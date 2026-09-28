`include "uncore_def.sv"

module stb_dc_front
  import uncore_pkg::*;
  import stb_dc_pkg::*;
#(
  parameter int unsigned DEPTH = 4
) (
  input  logic                  clk_i,
  input  logic                  rst_n_i,
  input  wire  Slv_TL_A_Chan_t  a_i,
  input  logic                  a_valid_i,
  output logic                  a_ready_o,
  output Slv_TL_D_Chan_t        d_o,
  output logic                  d_valid_o,
  input  logic                  block_i,
  output logic                  quiescent_o,
  output logic                  drained_o,
  output dc_req_t               req_o,
  output logic                  req_valid_o,
  input  logic                  req_ready_i,
  input  logic                  pending_valid_i,
  input  wire  dc_req_t         pending_i,
  input  logic                  result_valid_i,
  input  logic                  result_direct_i,
  input  logic                  result_failed_i,
  input  logic [63:0]           result_data_i,
  input  logic                  work_done_i,
  input  logic                  lr_set_i,
  input  logic                  cbo_accept_i,
  input  logic                  lr_invalid_i
);

  localparam int unsigned PTR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
  localparam int unsigned COUNT_WIDTH = $clog2(DEPTH + 1);

  logic [DEPTH-1:0] valid_q;
  logic [31:0] addr_q [DEPTH];
  logic [63:0] data_q [DEPTH];
  logic [7:0] mask_q [DEPTH];
  logic [PTR_WIDTH-1:0] head_q;
  logic [PTR_WIDTH-1:0] tail_q;
  logic [COUNT_WIDTH-1:0] count_q;

  logic front_q;
  logic atomic_rsp_q;
  logic atomic_work_q;
  logic stall_q;
  req_kind_e kind_q;
  req_kind_e kind_in;
  Slv_TL_A_Chan_t front_a_q;
  Slv_TL_D_Chan_t d_q;
  logic d_valid_q;
  logic [63:0] fwd_q;
  logic [63:0] fwd_data;
  logic [7:0] fmask_q;
  logic [7:0] fwd_mask;
  logic res_q;
  logic lr_killed_q;
  logic [31:0] res_addr_q;
  logic [7:0] res_mask_q;

  logic can_merge;
  logic full_forward;
  logic is_store;
  logic is_load;
  logic is_atomic;
  logic legal;
  logic [PTR_WIDTH-1:0] merge_index;
  logic release_front;
  logic normal_release;
  logic atomic_release;
  logic front_window;
  logic a_fire;
  logic store_fire;
  logic load_fire;
  logic atomic_fire;
  logic sc_ok;
  logic sc_fail;
  logic drain_fire;
  logic alloc_fire;
  logic dc_selected;
  logic [63:0] returned_data;
  logic [31:0] reservation_addr_now;
  logic [7:0] reservation_mask_now;

  function automatic logic [PTR_WIDTH-1:0] advance(
    input logic [PTR_WIDTH-1:0] pointer
  );
    return (pointer == PTR_WIDTH'(DEPTH - 1)) ? '0 : pointer + 1'b1;
  endfunction

  always_comb begin
    kind_in = REQ_LOAD;
    legal = 1'b1;
    case (a_i.tl_a_opcode)
      `PutFullData: begin
        kind_in = REQ_STORE;
        legal = a_i.tl_a_param == TL_PARAM_NORMAL;
      end
      `PutPartialData: begin
        kind_in = (a_i.tl_a_param == TL_PARAM_ATOMIC) ? REQ_SC : REQ_STORE;
        legal = a_i.tl_a_param inside {TL_PARAM_NORMAL, TL_PARAM_ATOMIC};
      end
      `ArithmeticData, `LogicalData: begin
        kind_in = REQ_AMO;
      end
      `Get: begin
        kind_in = (a_i.tl_a_param == TL_PARAM_ATOMIC) ? REQ_LR : REQ_LOAD;
        legal = a_i.tl_a_param inside {TL_PARAM_NORMAL, TL_PARAM_ATOMIC};
      end
      default: begin
        legal = 1'b0;
      end
    endcase

    is_store = kind_in == REQ_STORE;
    is_load = kind_in == REQ_LOAD;
    is_atomic = kind_in inside {REQ_LR, REQ_SC, REQ_AMO};

    can_merge = 1'b0;
    merge_index = '0;
    fwd_data = '0;
    fwd_mask = '0;
    if (pending_valid_i &&
        pending_i.addr[31:3] == a_i.tl_a_addr[31:3]) begin
      fwd_data = pending_i.data;
      fwd_mask = pending_i.mask;
    end
    for (int unsigned entry_idx = 0; entry_idx < DEPTH; entry_idx++) begin
      if (valid_q[entry_idx] &&
          addr_q[entry_idx][31:3] == a_i.tl_a_addr[31:3]) begin
        can_merge = 1'b1;
        merge_index = PTR_WIDTH'(entry_idx);
        fwd_data = merge_bytes(fwd_data, data_q[entry_idx], mask_q[entry_idx]);
        fwd_mask = fwd_mask | mask_q[entry_idx];
      end
    end
    full_forward = (fwd_mask & a_i.tl_a_mask) == a_i.tl_a_mask;

    returned_data = result_failed_i ? 64'b0 :
        ((kind_q == REQ_LOAD) ?
            merge_bytes(result_data_i, fwd_q, fmask_q) : result_data_i);

    d_valid_o = d_valid_q || (result_valid_i && result_direct_i);
    d_o = d_q;
    if (result_valid_i && result_direct_i) begin
      d_o = '0;
      d_o.tl_d_opcode = `AccessAckData;
      d_o.tl_d_source = front_a_q.tl_a_source;
      d_o.tl_d_size = front_a_q.tl_a_size;
      d_o.tl_d_data = returned_data;
    end
    d_o.tl_d_error = 1'b0;
    d_o.tl_d_param = TL_PARAM_NORMAL;

    normal_release = front_q && (kind_q == REQ_LOAD) && d_valid_o;
    atomic_release = front_q && (kind_q != REQ_LOAD) &&
        (atomic_rsp_q || d_valid_o) && (atomic_work_q || work_done_i);
    release_front = normal_release || atomic_release;
    front_window = !front_q || release_front;

    // LSU D ready is tied high, so an existing response completes on this edge.
    quiescent_o = front_window;
    drained_o = (count_q == '0) && !pending_valid_i;

    sc_ok = res_q && !lr_invalid_i &&
        (res_addr_q[31:3] == a_i.tl_a_addr[31:3]) &&
        (res_mask_q == a_i.tl_a_mask);

    // A Store accepted on the LR response edge must compare against the
    // reservation established on that edge rather than the previous one.
    reservation_addr_now = (lr_set_i && !lr_killed_q && !lr_invalid_i) ?
        front_a_q.tl_a_addr : res_addr_q;
    reservation_mask_now = (lr_set_i && !lr_killed_q && !lr_invalid_i) ?
        front_a_q.tl_a_mask : res_mask_q;

    a_ready_o = 1'b0;
    if (front_window && !block_i && legal) begin
      if (is_store) begin
        a_ready_o = can_merge || (count_q < COUNT_WIDTH'(DEPTH));
      end else if (is_load) begin
        a_ready_o = full_forward || req_ready_i;
      end else if (is_atomic) begin
        a_ready_o = drained_o && req_ready_i;
      end
    end

    a_fire = a_valid_i && a_ready_o;
    store_fire = a_fire && is_store;
    load_fire = a_fire && is_load;
    atomic_fire = a_fire && is_atomic;
    sc_fail = atomic_fire && (kind_in == REQ_SC) && !sc_ok;

    dc_selected = a_valid_i && front_window && !block_i && legal &&
        ((is_load && !full_forward) ||
            (is_atomic && drained_o && !((kind_in == REQ_SC) && !sc_ok)));

    req_valid_o = dc_selected;
    req_o = '0;
    req_o.kind = kind_in;
    req_o.addr = a_i.tl_a_addr;
    req_o.data = a_i.tl_a_data;
    req_o.mask = a_i.tl_a_mask;
    req_o.opcode = a_i.tl_a_opcode;
    req_o.param = a_i.tl_a_param;
    req_o.size = a_i.tl_a_size;

    if (!dc_selected && (count_q != '0) && (!stall_q || normal_release)) begin
      req_valid_o = 1'b1;
      req_o.kind = REQ_STORE;
      req_o.addr = addr_q[head_q];
      req_o.size = TL_SIZE_DOUBLEWORD;
      req_o.data = data_q[head_q];
      req_o.mask = mask_q[head_q];
      req_o.param = TL_PARAM_NORMAL;
      if (store_fire && can_merge && (merge_index == head_q)) begin
        req_o.data = merge_bytes(req_o.data, a_i.tl_a_data, a_i.tl_a_mask);
        req_o.mask = req_o.mask | a_i.tl_a_mask;
      end
      req_o.opcode = (req_o.mask == 8'hff) ? `PutFullData : `PutPartialData;
    end

    drain_fire = req_valid_o && req_ready_i && (req_o.kind == REQ_STORE);
    alloc_fire = store_fire && !can_merge;
  end

  always_ff @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
      valid_q <= '0;
      head_q <= '0;
      tail_q <= '0;
      count_q <= '0;
      front_q <= 1'b0;
      kind_q <= REQ_LOAD;
      front_a_q <= '0;
      d_valid_q <= 1'b0;
      d_q <= '0;
      fwd_q <= '0;
      fmask_q <= '0;
      stall_q <= 1'b0;
      atomic_rsp_q <= 1'b0;
      atomic_work_q <= 1'b0;
      res_q <= 1'b0;
      res_addr_q <= '0;
      res_mask_q <= '0;
      lr_killed_q <= 1'b0;
      for (int unsigned entry_idx = 0; entry_idx < DEPTH; entry_idx++) begin
        addr_q[entry_idx] <= '0;
        data_q[entry_idx] <= '0;
        mask_q[entry_idx] <= '0;
      end
    end else begin
      d_valid_q <= 1'b0;

      if (result_valid_i && !result_direct_i) begin
        d_valid_q <= 1'b1;
        d_q <= '0;
        d_q.tl_d_opcode <= `AccessAckData;
        d_q.tl_d_size <= front_a_q.tl_a_size;
        d_q.tl_d_source <= front_a_q.tl_a_source;
        d_q.tl_d_data <= returned_data;
      end

      if (front_q && (kind_q != REQ_LOAD)) begin
        if (d_valid_o) begin
          atomic_rsp_q <= 1'b1;
        end
        if (work_done_i) begin
          atomic_work_q <= 1'b1;
        end
      end

      if (release_front) begin
        front_q <= 1'b0;
        atomic_rsp_q <= 1'b0;
        atomic_work_q <= 1'b0;
        if (normal_release) begin
          stall_q <= 1'b0;
        end
      end

      if (load_fire || atomic_fire) begin
        front_q <= 1'b1;
        kind_q <= kind_in;
        front_a_q <= a_i;
        atomic_rsp_q <= 1'b0;
        atomic_work_q <= sc_fail;
        lr_killed_q <= lr_invalid_i;
        fwd_q <= fwd_data;
        fmask_q <= fwd_mask;
        if (load_fire) begin
          stall_q <= !full_forward && (|fwd_mask);
        end
      end

      if (store_fire || (load_fire && full_forward) || sc_fail) begin
        d_valid_q <= 1'b1;
        d_q <= '0;
        d_q.tl_d_opcode <= store_fire ? `AccessAck : `AccessAckData;
        d_q.tl_d_size <= a_i.tl_a_size;
        d_q.tl_d_source <= a_i.tl_a_source;
        d_q.tl_d_data <= store_fire ? 64'd0 :
            (sc_fail ? 64'd1 : fwd_data);
      end

      count_q <= count_q + COUNT_WIDTH'(alloc_fire) - COUNT_WIDTH'(drain_fire);
      if (drain_fire) begin
        valid_q[head_q] <= 1'b0;
        head_q <= advance(head_q);
      end

      if (store_fire) begin
        if (can_merge) begin
          if (!(drain_fire && (merge_index == head_q))) begin
            data_q[merge_index] <= merge_bytes(
                data_q[merge_index], a_i.tl_a_data, a_i.tl_a_mask);
            mask_q[merge_index] <= mask_q[merge_index] | a_i.tl_a_mask;
          end
        end else begin
          valid_q[tail_q] <= 1'b1;
          addr_q[tail_q] <= {a_i.tl_a_addr[31:3], 3'b0};
          data_q[tail_q] <= a_i.tl_a_data;
          mask_q[tail_q] <= a_i.tl_a_mask;
          tail_q <= advance(tail_q);
        end
      end

      if (lr_set_i && !lr_killed_q && !lr_invalid_i) begin
        res_q <= 1'b1;
        res_addr_q <= front_a_q.tl_a_addr;
        res_mask_q <= front_a_q.tl_a_mask;
      end
      if (lr_invalid_i) begin
        res_q <= 1'b0;
        if (front_q && (kind_q == REQ_LR)) begin
          lr_killed_q <= 1'b1;
        end
      end
      if (cbo_accept_i || (atomic_fire && (kind_in == REQ_SC))) begin
        res_q <= 1'b0;
      end
      if ((store_fire || (atomic_fire && (kind_in == REQ_AMO))) &&
          (reservation_addr_now[31:3] == a_i.tl_a_addr[31:3]) &&
          (|(reservation_mask_now & a_i.tl_a_mask))) begin
        res_q <= 1'b0;
      end
    end
  end

`ifndef SYNTHESIS
  initial begin
    assert (DEPTH >= 1) else $fatal(1, "STB depth must be positive");
  end

  always_ff @(posedge clk_i) begin
    if (rst_n_i) begin
      assert (count_q <= COUNT_WIDTH'(DEPTH))
        else $fatal(1, "STB count overflow");
      assert (!(d_valid_q && result_valid_i && result_direct_i))
        else $fatal(1, "D response collision");
      assert (!(result_valid_i && !result_direct_i &&
          (store_fire || (load_fire && full_forward) || sc_fail)))
        else $fatal(1, "D register overwrite");

      for (int unsigned first_idx = 0; first_idx < DEPTH; first_idx++) begin
        for (int unsigned second_idx = first_idx + 1;
             second_idx < DEPTH;
             second_idx++) begin
          assert (!(valid_q[first_idx] && valid_q[second_idx] &&
                    (addr_q[first_idx] == addr_q[second_idx])))
            else $fatal(1, "duplicate STB address");
        end
      end

      if (a_fire) begin
        if (is_load) begin
          assert (a_i.tl_a_mask == 8'hff && a_i.tl_a_addr[2:0] == 3'b000)
            else $fatal(1, "unaligned/non-doubleword load");
        end
        if (is_atomic) begin
          assert (a_i.tl_a_size == TL_SIZE_WORD &&
                  a_i.tl_a_addr[1:0] == 2'b00 &&
                  a_i.tl_a_mask ==
                      (a_i.tl_a_addr[2] ? 8'hf0 : 8'h0f))
            else $fatal(1, "invalid atomic lane");
        end
      end
    end
  end
`endif

endmodule

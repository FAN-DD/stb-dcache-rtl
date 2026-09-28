`include "dcache_def.sv"

module stb_dc_core
  import uncore_pkg::*;
  import kratos_pkg::*;
  import stb_dc_pkg::*;
  import prim_secded_pkg::*;
(
  input  logic                              clk_i,
  input  logic                              rst_n_i,
  input  wire  dc_req_t                     req_i,
  input  logic                              req_valid_i,
  output logic                              req_ready_o,
  output logic                              pending_valid_o,
  output dc_req_t                           pending_o,
  output logic                              result_valid_o,
  output logic                              result_direct_o,
  output logic                              result_failed_o,
  output logic [63:0]                       result_data_o,
  output logic                              work_done_o,
  output logic                              lr_set_o,
  input  logic                              front_quiet_i,
  input  logic                              drained_i,
  input  logic                              cbo_req_i,
  input  cbo_type_e                         cbo_type_i,
  input  logic [31:0]                       cbo_addr_i,
  output logic                              cbo_accept_o,
  output logic                              front_block_o,
  output logic                              cbo_ack_o,
  output logic                              cbo_bus_err_o,
  output logic                              cbo_ecc_err_o,
  output logic                              busy_o,
  input  logic                              check_en_i,
  output logic                              tag_err_valid_o,
  output logic                              data_err_valid_o,
  output logic [17:0]                       tag_err_addr_o,
  output logic [17:0]                       data_err_addr_o,
  output logic [1:0]                        tag_err_type_o,
  output logic [1:0]                        data_err_type_o,
  output logic [`dcTagIdxWidth-1:0]         tag_addr_o,
  output logic [`dcTagRamWidth-1:0]         tag_wdata_o,
  input  logic [`dcTagRamWidth-1:0]         tag_rdata_i,
  output logic                              tag_ceb_o,
  output logic                              tag_web_o,
  output logic [3:0][`dcDataIdxWidth-1:0]  data_addr_o,
  output logic [3:0][71:0]                  data_wdata_o,
  input  wire  [3:0][71:0]                  data_rdata_i,
  output logic [3:0]                        data_ceb_o,
  output logic [3:0]                        data_web_o,
  output logic [3:0][8:0]                   data_wm_o,
  output logic                              bus_a_valid_o,
  input  logic                              bus_a_ready_i,
  output Slv_TL_A_Chan_t                    bus_a_o,
  input  logic                              bus_d_valid_i,
  output logic                              bus_d_ready_o,
  input  wire  Slv_TL_D_Chan_t              bus_d_i
);

  localparam int unsigned INDEX_WIDTH = `dcTagIdxWidth;
  localparam int unsigned DATA_INDEX_WIDTH = `dcDataIdxWidth;
  localparam int unsigned TAG_WIDTH = `dcTagWidth;
  localparam int unsigned TAG_RAW_WIDTH = `dcTagRamRawWidth;
  localparam int unsigned TAG_CODE_WIDTH = `dcTagRamWidth;
  localparam int unsigned SET_COUNT = `dcTagEntry;
  localparam logic [1:0] LAST_BEAT = 2'd3;
  localparam logic [1:0] SCAN_READ = 2'd0;
  localparam logic [1:0] SCAN_WAIT = 2'd1;
  localparam logic [1:0] SCAN_EVAL = 2'd2;
  localparam logic [1:0] ECC_SINGLE = 2'b01;
  localparam logic [1:0] ECC_DOUBLE = 2'b10;
  localparam logic [8:0] DATA_FULL_WRITE_MASK = 9'h1ff;
  localparam logic [8:0] DATA_LOW_WORD_WRITE_MASK = 9'h10f;
  localparam logic [8:0] DATA_HIGH_WORD_WRITE_MASK = 9'h1f0;

  typedef enum logic [3:0] {
    IDLE,
    LOOKUP_ECC,
    LOOKUP_EVAL,
    AMO_WRITE,
    SCRUB,
    VICTIM_READ,
    WB_WAIT,
    REFILL,
    ZERO_WRITE,
    CBO_TAG,
    SCAN
  } state_e;
  typedef struct packed {
    state_e state;
    state_e resume;
    dc_req_t req;
    logic [INDEX_WIDTH-1:0] set_idx;
    logic [1:0] way;
    logic [31:0] victim_base;
    logic [3:0] issued;
    logic [3:0] received;
    logic [3:0] repair;
    logic bus_started;
    logic rf_error;
    logic rf_done;
    logic critical_seen;
    logic critical_err;
    logic response_issued;
    logic [63:0] critical_old;
    logic amo_phase;
    logic write_valid;
    logic write_last;
    logic [71:0] write_code;
    logic [DATA_INDEX_WIDTH-1:0] write_addr;
    logic [8:0] write_mask;
    logic write_tag;
    logic [TAG_CODE_WIDTH-1:0] install_tag;
    logic new_allocation;
    logic [2:0] zero_count;
    logic [1:0] scan_phase;
    logic scrub_tag;
    logic scrub_data;
    logic [63:0] scrub_raw;
    logic [1:0] scrub_beat;
    logic cbo_active;
    logic cbo_armed;
    logic cbo_bus_seen;
    logic cbo_ecc_seen;
    cbo_type_e cbo_type;
    logic [31:0] cbo_addr;
  } control_t;
  control_t c_q;
  control_t c_d;
  logic [3:0] valid_q [SET_COUNT];
  logic [15:0] lfsr_q;
  logic [TAG_RAW_WIDTH-1:0] tag_q;
  logic [TAG_RAW_WIDTH-1:0] tag_dec;
  logic [TAG_RAW_WIDTH-1:0] tag_raw_write;
  logic tag_single_q;
  logic tag_double_q;
  logic tag_single_dec;
  logic tag_double_dec;
  logic [3:0][63:0] data_q;
  logic [3:0][63:0] data_dec;
  logic [3:0] single_q;
  logic [3:0] double_q;
  logic [3:0] single_dec;
  logic [3:0] double_dec;
  logic rd_tag_q;
  logic [3:0] rd_data_q;
  logic [INDEX_WIDTH-1:0] rd_set_q;
  logic [1:0] rd_beat_q;
  logic [1:0] rd_way_q;
  logic rd_victim_q;
  logic victim_event_q;
  logic victim_single_q;
  logic victim_double_q;
  logic [DATA_INDEX_WIDTH-1:0] victim_event_index_q;
  logic [1:0] victim_event_way_q;
  logic [3:0][63:0] line_q;
  logic line_reuse;
  logic [1:0] reuse_beat;
  logic [1:0] reuse_way;
  logic bus_start;
  logic bus_put;
  logic bus_idle;
  logic bus_refill_ready;
  logic bus_refill_fire;
  logic bus_done;
  logic bus_failed;
  logic [31:0] bus_base;
  logic [1:0] bus_beat;
  logic [63:0] bus_data;
  logic bus_error;
  logic [3:0] hit_mask;
  logic [3:0] dirty_mask;
  logic hit;
  logic [1:0] hit_way;
  logic [1:0] victim_way;
  logic [1:0] first_way;
  logic [TAG_RAW_WIDTH-1:0] clean_tag;
  logic [TAG_RAW_WIDTH-1:0] modified_tag;
  logic [63:0] selected_data;
  logic [63:0] new_data;
  logic tag_event;
  logic data_event;
  logic [1:0] tag_event_type;
  logic [1:0] data_event_type;
  logic [1:0] data_event_way;
  logic [DATA_INDEX_WIDTH-1:0] data_event_index;
  logic [INDEX_WIDTH-1:0] tag_event_index;
  logic valid_write;
  logic valid_clear_all;
  logic advance_lfsr;
  logic [INDEX_WIDTH-1:0] valid_index;
  logic [3:0] valid_value;
  logic finish;
  logic finish_cbo;
  logic do_lookup;
  logic start_victim;
  logic begin_refill;
  logic begin_zero;
  logic reuse_lookup;
  logic scan_advance;
  logic [1:0] selected_way;
  logic [1:0] missing_beat;
  logic missing_found;
  logic cbo_execute;
  logic turnover;
  dc_req_t lookup_req;
  cbo_type_e executing_cbo;
  logic [31:0] executing_addr;

  function automatic logic [INDEX_WIDTH-1:0] set_of(input logic [31:0] addr);
    return addr[5 +: INDEX_WIDTH];
  endfunction

  function automatic logic [TAG_WIDTH-1:0] tag_of(input logic [31:0] addr);
    return addr[5 + INDEX_WIDTH +: TAG_WIDTH];
  endfunction

  function automatic logic [TAG_CODE_WIDTH-1:0] encode_tag(
    input logic [TAG_RAW_WIDTH-1:0] raw
  );
    case (TAG_RAW_WIDTH)
      52: return TAG_CODE_WIDTH'(prim_secded_59_52_enc(52'(raw)));
      56: return TAG_CODE_WIDTH'(prim_secded_63_56_enc(56'(raw)));
      60: return TAG_CODE_WIDTH'(prim_secded_68_60_enc(60'(raw)));
      64: return TAG_CODE_WIDTH'(prim_secded_72_64_enc(64'(raw)));
      default: return '0;
    endcase
  endfunction

  function automatic logic [31:0] line_address(
    input logic [TAG_WIDTH-1:0] tag,
    input logic [INDEX_WIDTH-1:0] index
  );
    return {`dcAddrMSB, tag, index, 5'b0};
  endfunction

  ecc_codec #(
    .RAW_DATA_WIDTH(TAG_RAW_WIDTH),
    .ECC_DATA_WIDTH(TAG_CODE_WIDTH)
  ) u_tag_codec (
    .raw_encode_data({TAG_RAW_WIDTH{1'b0}}),
    .encode_ecc_data(),
    .ecc_decode_data(tag_rdata_i),
    .decode_raw_data(tag_dec),
    .ecc_single_err(tag_single_dec),
    .ecc_double_err(tag_double_dec)
  );

  for (genvar way_idx = 0; way_idx < 4; way_idx++) begin : g_data_codec
    ecc_codec #(
      .RAW_DATA_WIDTH(64),
      .ECC_DATA_WIDTH(72)
    ) u_codec (
      .raw_encode_data(64'b0),
      .encode_ecc_data(),
      .ecc_decode_data(data_rdata_i[way_idx]),
      .decode_raw_data(data_dec[way_idx]),
      .ecc_single_err(single_dec[way_idx]),
      .ecc_double_err(double_dec[way_idx])
    );
  end

  stb_dc_biu u_biu (
    .clk_i,
    .rst_n_i,
    .start_i(bus_start),
    .put_i(bus_put),
    .base_i(bus_base),
    .line_i(line_q),
    .idle_o(bus_idle),
    .refill_ready_i(bus_refill_ready),
    .refill_fire_o(bus_refill_fire),
    .refill_beat_o(bus_beat),
    .refill_data_o(bus_data),
    .refill_error_o(bus_error),
    .done_o(bus_done),
    .failed_o(bus_failed),
    .a_valid_o(bus_a_valid_o),
    .a_ready_i(bus_a_ready_i),
    .a_o(bus_a_o),
    .d_valid_i(bus_d_valid_i),
    .d_ready_o(bus_d_ready_o),
    .d_i(bus_d_i)
  );

  always_comb begin
    hit_mask = '0;
    dirty_mask = '0;
    clean_tag = tag_q;
    hit_way = '0;
    victim_way = lfsr_q[1:0];
    first_way = '0;
    for (int way_idx = 3; way_idx >= 0; way_idx--) begin
      hit_mask[way_idx] = valid_q[c_q.set_idx][way_idx] &&
          (tag_q[way_idx * (TAG_WIDTH + 1) +: TAG_WIDTH] ==
              tag_of(c_q.req.addr));
      dirty_mask[way_idx] = valid_q[c_q.set_idx][way_idx] &&
          tag_q[way_idx * (TAG_WIDTH + 1) + TAG_WIDTH];
      if (hit_mask[way_idx]) begin
        hit_way = 2'(way_idx);
      end
      if (!valid_q[c_q.set_idx][way_idx]) begin
        victim_way = 2'(way_idx);
        clean_tag[way_idx * (TAG_WIDTH + 1) +: (TAG_WIDTH + 1)] = '0;
      end
      if (dirty_mask[way_idx]) begin
        first_way = 2'(way_idx);
      end
    end
    hit = |hit_mask;
    selected_data = data_q[hit_way];
  end

  always_comb begin
    c_d = c_q;
    tag_addr_o = c_q.set_idx;
    tag_wdata_o = '0;
    tag_raw_write = clean_tag;
    tag_ceb_o = 1'b1;
    tag_web_o = 1'b1;
    data_addr_o = '0;
    data_wdata_o = '0;
    data_wm_o = '0;
    data_ceb_o = '1;
    data_web_o = '1;
    bus_start = 1'b0;
    bus_put = 1'b0;
    bus_base = {c_q.req.addr[31:5], 5'b0};
    bus_refill_ready = !c_q.amo_phase;
    result_valid_o = 1'b0;
    result_direct_o = 1'b0;
    result_failed_o = 1'b0;
    result_data_o = '0;
    work_done_o = 1'b0;
    lr_set_o = 1'b0;
    tag_event = 1'b0;
    data_event = victim_event_q && (victim_single_q || victim_double_q);
    tag_event_type = '0;
    tag_event_index = c_q.set_idx;
    data_event_type = victim_double_q ? ECC_DOUBLE : ECC_SINGLE;
    data_event_index = victim_event_index_q;
    data_event_way = victim_event_way_q;
    valid_write = 1'b0;
    valid_clear_all = 1'b0;
    valid_index = c_q.set_idx;
    valid_value = valid_q[c_q.set_idx];
    advance_lfsr = 1'b0;
    finish = 1'b0;
    finish_cbo = 1'b0;
    do_lookup = 1'b0;
    start_victim = 1'b0;
    begin_refill = 1'b0;
    begin_zero = 1'b0;
    reuse_lookup = 1'b0;
    scan_advance = 1'b0;
    selected_way = hit ? hit_way : victim_way;
    lookup_req = req_i;
    line_reuse = 1'b0;
    reuse_beat = c_q.req.addr[4:3];
    reuse_way = selected_way;
    missing_found = 1'b0;
    missing_beat = '0;
    modified_tag = clean_tag;
    new_data = '0;
    executing_cbo = c_q.cbo_active ? c_q.cbo_type : cbo_type_i;
    executing_addr = c_q.cbo_active ? c_q.cbo_addr : cbo_addr_i;
    front_block_o = c_q.cbo_active || (c_q.cbo_armed && cbo_req_i);
    cbo_accept_o = !c_q.cbo_active && c_q.cbo_armed && cbo_req_i &&
        (c_q.state == IDLE) && drained_i && front_quiet_i;
    cbo_execute = (c_q.cbo_active || cbo_accept_o) &&
        (c_q.state == IDLE) && drained_i && front_quiet_i;
    turnover = (c_q.state == LOOKUP_EVAL) &&
        (c_q.req.kind == REQ_LOAD) && hit &&
        !tag_single_q && !single_q[hit_way];
    req_ready_o = ((c_q.state == IDLE) || turnover) && !cbo_execute;
    pending_valid_o = (c_q.state != IDLE) && (c_q.req.kind == REQ_STORE);
    pending_o = c_q.req;
    busy_o = (c_q.state != IDLE) || !bus_idle || c_q.cbo_active;

    if (!cbo_req_i && !c_q.cbo_active) begin
      c_d.cbo_armed = 1'b1;
    end
    if (cbo_accept_o) begin
      c_d.cbo_active = 1'b1;
      c_d.cbo_armed = 1'b0;
      c_d.cbo_type = cbo_type_i;
      c_d.cbo_addr = cbo_addr_i;
      c_d.cbo_bus_seen = 1'b0;
      c_d.cbo_ecc_seen = 1'b0;
    end
    if (victim_event_q && victim_double_q && (c_q.req.kind == REQ_CBO)) begin
      c_d.cbo_ecc_seen = 1'b1;
    end

    case (c_q.state)
      IDLE: begin
      end
      LOOKUP_ECC: begin
        c_d.state = LOOKUP_EVAL;
      end
      LOOKUP_EVAL: begin
        tag_event = tag_single_q || tag_double_q;
        tag_event_type = tag_double_q ? ECC_DOUBLE : ECC_SINGLE;
        if (hit && (c_q.req.kind != REQ_CBO)) begin
          data_event = single_q[hit_way] || double_q[hit_way];
          data_event_type = double_q[hit_way] ? ECC_DOUBLE : ECC_SINGLE;
          data_event_way = hit_way;
          data_event_index = {c_q.set_idx, c_q.req.addr[4:3]};
        end
        if (tag_double_q && (c_q.req.kind == REQ_CBO)) begin
          c_d.cbo_ecc_seen = 1'b1;
        end

        // Full Store/SC writes repair their selected codeword and Tag in place.
        if ((tag_single_q ||
                (hit && single_q[hit_way] &&
                    (c_q.req.kind inside {REQ_LOAD, REQ_LR}))) &&
            !(hit && (c_q.req.kind inside {REQ_STORE, REQ_SC, REQ_AMO}))) begin
          c_d.scrub_tag = tag_single_q;
          c_d.scrub_data = hit && single_q[hit_way] &&
              (c_q.req.kind inside {REQ_LOAD, REQ_LR});
          c_d.scrub_raw = selected_data;
          c_d.scrub_beat = c_q.req.addr[4:3];
          c_d.way = hit_way;
          c_d.resume = LOOKUP_EVAL;
          c_d.state = SCRUB;
        end else if (c_q.req.kind == REQ_CBO) begin
          case (c_q.cbo_type)
            CBO_INVAL: begin
              if (hit) begin
                valid_write = 1'b1;
                valid_value[hit_way] = 1'b0;
              end
              finish = 1'b1;
            end
            CBO_CLEAN, CBO_FLUSH: begin
              if (hit && dirty_mask[hit_way]) begin
                start_victim = 1'b1;
                reuse_lookup = 1'b1;
              end else begin
                if (hit && (c_q.cbo_type == CBO_FLUSH)) begin
                  valid_write = 1'b1;
                  valid_value[hit_way] = 1'b0;
                end
                finish = 1'b1;
              end
            end
            CBO_ZERO: begin
              if (!hit && dirty_mask[victim_way]) begin
                start_victim = 1'b1;
                reuse_lookup = 1'b1;
              end else begin
                begin_zero = 1'b1;
              end
            end
            default: begin
              finish = 1'b1;
            end
          endcase
        end else if (hit) begin
          c_d.way = hit_way;
          if (c_q.req.kind inside {REQ_LOAD, REQ_LR}) begin
            result_valid_o = 1'b1;
            result_direct_o = 1'b1;
            result_data_o = (c_q.req.kind == REQ_LR) ?
                lane_result(selected_data, c_q.req.addr[2]) : selected_data;
            lr_set_o = c_q.req.kind == REQ_LR;
            finish = 1'b1;
          end else begin
            modified_tag[hit_way * (TAG_WIDTH + 1) + TAG_WIDTH] = 1'b1;
            new_data = (c_q.req.kind == REQ_AMO) ?
                amo_result(selected_data, c_q.req.data, c_q.req.addr[2],
                    c_q.req.opcode, c_q.req.param) :
                merge_bytes(selected_data, c_q.req.data, c_q.req.mask);
            if (c_q.req.kind == REQ_AMO) begin
              result_valid_o = 1'b1;
              result_direct_o = 1'b1;
              result_data_o = lane_result(selected_data, c_q.req.addr[2]);
              c_d.response_issued = 1'b1;
              c_d.write_valid = 1'b1;
              c_d.write_code = prim_secded_72_64_enc(new_data);
              c_d.write_addr = {c_q.set_idx, c_q.req.addr[4:3]};
              c_d.write_mask = c_q.req.addr[2] ?
                  DATA_HIGH_WORD_WRITE_MASK : DATA_LOW_WORD_WRITE_MASK;
              c_d.install_tag = encode_tag(modified_tag);
              c_d.write_tag = !dirty_mask[hit_way] || tag_single_q;
              c_d.state = AMO_WRITE;
              if (single_q[hit_way]) begin
                c_d.scrub_tag = 1'b0;
                c_d.scrub_data = 1'b1;
                c_d.scrub_raw = selected_data;
                c_d.scrub_beat = c_q.req.addr[4:3];
                c_d.resume = AMO_WRITE;
                c_d.state = SCRUB;
              end
            end else begin
              data_ceb_o[hit_way] = 1'b0;
              data_web_o[hit_way] = 1'b0;
              data_addr_o[hit_way] = {c_q.set_idx, c_q.req.addr[4:3]};
              data_wdata_o[hit_way] = prim_secded_72_64_enc(new_data);
              data_wm_o[hit_way] = DATA_FULL_WRITE_MASK;
              if (!dirty_mask[hit_way] || tag_single_q) begin
                tag_ceb_o = 1'b0;
                tag_web_o = 1'b0;
                tag_raw_write = modified_tag;
                tag_wdata_o = encode_tag(modified_tag);
              end
              if (c_q.req.kind == REQ_SC) begin
                result_valid_o = 1'b1;
                result_data_o = 64'd0;
              end
              finish = 1'b1;
            end
          end
        end else if (dirty_mask[victim_way]) begin
          start_victim = 1'b1;
          reuse_lookup = 1'b1;
        end else begin
          begin_refill = 1'b1;
        end
      end
      SCRUB: begin
        if (c_q.scrub_tag) begin
          tag_ceb_o = 1'b0;
          tag_web_o = 1'b0;
          tag_raw_write = clean_tag;
          tag_wdata_o = encode_tag(clean_tag);
        end
        if (c_q.scrub_data) begin
          data_ceb_o[c_q.way] = 1'b0;
          data_web_o[c_q.way] = 1'b0;
          data_addr_o[c_q.way] = {c_q.set_idx, c_q.scrub_beat};
          data_wdata_o[c_q.way] = prim_secded_72_64_enc(c_q.scrub_raw);
          data_wm_o[c_q.way] = DATA_FULL_WRITE_MASK;
        end
        c_d.scrub_tag = 1'b0;
        c_d.scrub_data = 1'b0;
        c_d.state = c_q.resume;
        if ((c_q.resume == LOOKUP_EVAL) && hit &&
            (c_q.req.kind inside {REQ_LOAD, REQ_LR})) begin
          result_valid_o = 1'b1;
          result_direct_o = 1'b1;
          result_data_o = (c_q.req.kind == REQ_LR) ?
              lane_result(selected_data, c_q.req.addr[2]) : selected_data;
          lr_set_o = c_q.req.kind == REQ_LR;
          finish = 1'b1;
        end
      end
      AMO_WRITE: begin
        data_ceb_o[c_q.way] = 1'b0;
        data_web_o[c_q.way] = 1'b0;
        data_addr_o[c_q.way] = c_q.write_addr;
        data_wdata_o[c_q.way] = c_q.write_code;
        data_wm_o[c_q.way] = c_q.write_mask;
        if (c_q.write_tag) begin
          tag_ceb_o = 1'b0;
          tag_web_o = 1'b0;
          tag_wdata_o = c_q.install_tag;
          tag_raw_write = c_q.install_tag[TAG_RAW_WIDTH-1:0];
        end
        c_d.write_valid = 1'b0;
        finish = 1'b1;
      end
      VICTIM_READ: begin
        for (int beat_idx = 3; beat_idx >= 0; beat_idx--) begin
          if (!c_q.issued[beat_idx]) begin
            missing_found = 1'b1;
            missing_beat = 2'(beat_idx);
          end
        end
        if (missing_found) begin
          data_ceb_o[c_q.way] = 1'b0;
          data_addr_o[c_q.way] = {c_q.set_idx, missing_beat};
          c_d.issued[missing_beat] = 1'b1;
        end
        if (rd_victim_q) begin
          c_d.received[rd_beat_q] = 1'b1;
          // These bits are the ECC output register boundary, not a control decision.
          c_d.repair[rd_beat_q] = single_dec[rd_way_q];
          if ((&c_d.received) && (&c_q.issued)) begin
            c_d.state = WB_WAIT;
          end
        end
      end
      WB_WAIT: begin
        if (|c_q.repair) begin
          for (int beat_idx = 3; beat_idx >= 0; beat_idx--) begin
            if (c_q.repair[beat_idx]) begin
              missing_beat = 2'(beat_idx);
            end
          end
          data_ceb_o[c_q.way] = 1'b0;
          data_web_o[c_q.way] = 1'b0;
          data_addr_o[c_q.way] = {c_q.set_idx, missing_beat};
          data_wdata_o[c_q.way] = prim_secded_72_64_enc(line_q[missing_beat]);
          data_wm_o[c_q.way] = DATA_FULL_WRITE_MASK;
          c_d.repair[missing_beat] = 1'b0;
        end else if (!c_q.bus_started) begin
          bus_start = bus_idle;
          bus_put = 1'b1;
          bus_base = c_q.victim_base;
          if (bus_start) begin
            c_d.bus_started = 1'b1;
          end
        end
        if (bus_done) begin
          c_d.bus_started = 1'b0;
          if (bus_failed) begin
            valid_write = 1'b1;
            valid_value[c_q.way] = 1'b0;
            if (c_q.req.kind == REQ_CBO) begin
              c_d.cbo_bus_seen = 1'b1;
              if (c_q.cbo_type == CBO_CLEAN_ALL) begin
                c_d.state = SCAN;
                c_d.scan_phase = SCAN_EVAL;
              end else begin
                finish = 1'b1;
              end
            end else begin
              if (c_q.req.kind != REQ_STORE) begin
                result_valid_o = 1'b1;
                result_failed_o = c_q.req.kind != REQ_SC;
                result_data_o = (c_q.req.kind == REQ_SC) ? 64'd1 : 64'd0;
              end
              finish = 1'b1;
            end
          end else if ((c_q.req.kind == REQ_CBO) &&
                       (c_q.cbo_type != CBO_ZERO)) begin
            c_d.state = CBO_TAG;
          end else begin
            valid_write = 1'b1;
            valid_value[c_q.way] = 1'b0;
            c_d.state = (c_q.req.kind == REQ_CBO) ? ZERO_WRITE : REFILL;
            c_d.zero_count = '0;
            c_d.rf_done = 1'b0;
            c_d.rf_error = 1'b0;
          end
        end
      end
      REFILL: begin
        c_d.write_valid = 1'b0;
        if (!c_q.bus_started) begin
          bus_start = bus_idle;
          if (bus_start) begin
            c_d.bus_started = 1'b1;
          end
        end
        if (c_q.write_valid) begin
          data_ceb_o[c_q.way] = 1'b0;
          data_web_o[c_q.way] = 1'b0;
          data_addr_o[c_q.way] = c_q.write_addr;
          data_wdata_o[c_q.way] = c_q.write_code;
          data_wm_o[c_q.way] = DATA_FULL_WRITE_MASK;
          if (c_q.write_last && !c_q.rf_error) begin
            tag_ceb_o = 1'b0;
            tag_web_o = 1'b0;
            tag_wdata_o = c_q.install_tag;
            tag_raw_write = c_q.install_tag[TAG_RAW_WIDTH-1:0];
            valid_write = 1'b1;
            valid_value[c_q.way] = 1'b1;
            advance_lfsr = c_q.new_allocation;
            if (c_q.req.kind == REQ_LR) begin
              result_valid_o = 1'b1;
              result_data_o = lane_result(c_q.critical_old, c_q.req.addr[2]);
              lr_set_o = 1'b1;
            end
            if (c_q.req.kind == REQ_SC) begin
              result_valid_o = 1'b1;
              result_data_o = 64'd0;
            end
            finish = 1'b1;
          end
        end
        if (c_q.amo_phase) begin
          c_d.amo_phase = 1'b0;
          result_valid_o = !c_q.response_issued;
          result_direct_o = 1'b1;
          result_failed_o = c_q.critical_err;
          result_data_o = lane_result(c_q.critical_old, c_q.req.addr[2]);
          c_d.response_issued = 1'b1;
          if (!c_q.rf_error) begin
            c_d.write_valid = 1'b1;
            c_d.write_addr = {c_q.set_idx, c_q.req.addr[4:3]};
            c_d.write_code = prim_secded_72_64_enc(
                amo_result(c_q.critical_old, c_q.req.data, c_q.req.addr[2],
                    c_q.req.opcode, c_q.req.param));
            c_d.write_last = c_q.rf_done;
          end
        end
        if (c_q.rf_done && c_q.rf_error && !c_q.amo_phase &&
            !c_d.write_valid) begin
          if (c_q.req.kind inside {REQ_LR, REQ_SC}) begin
            result_valid_o = 1'b1;
            result_failed_o = c_q.req.kind == REQ_LR;
            result_data_o = (c_q.req.kind == REQ_SC) ? 64'd1 : 64'd0;
          end
          finish = 1'b1;
        end
      end
      ZERO_WRITE: begin
        data_ceb_o[c_q.way] = 1'b0;
        data_web_o[c_q.way] = 1'b0;
        data_addr_o[c_q.way] = {c_q.set_idx, c_q.zero_count[1:0]};
        data_wdata_o[c_q.way] = prim_secded_72_64_enc(64'b0);
        data_wm_o[c_q.way] = DATA_FULL_WRITE_MASK;
        c_d.zero_count = c_q.zero_count + 1'b1;
        if (c_q.zero_count == 3'd3) begin
          tag_ceb_o = 1'b0;
          tag_web_o = 1'b0;
          tag_wdata_o = c_q.install_tag;
          tag_raw_write = c_q.install_tag[TAG_RAW_WIDTH-1:0];
          valid_write = 1'b1;
          valid_value[c_q.way] = 1'b1;
          advance_lfsr = c_q.new_allocation;
          finish = 1'b1;
        end
      end
      CBO_TAG: begin
        modified_tag[c_q.way * (TAG_WIDTH + 1) + TAG_WIDTH] = 1'b0;
        tag_ceb_o = 1'b0;
        tag_web_o = 1'b0;
        tag_raw_write = modified_tag;
        tag_wdata_o = encode_tag(modified_tag);
        if (c_q.cbo_type == CBO_FLUSH) begin
          valid_write = 1'b1;
          valid_value[c_q.way] = 1'b0;
        end
        if (c_q.cbo_type == CBO_CLEAN_ALL) begin
          if (|(dirty_mask & ~(4'b0001 << c_q.way))) begin
            for (int way_idx = 3; way_idx >= 0; way_idx--) begin
              if (dirty_mask[way_idx] && (2'(way_idx) != c_q.way)) begin
                selected_way = 2'(way_idx);
              end
            end
            start_victim = 1'b1;
            reuse_lookup = 1'b0;
          end else begin
            scan_advance = 1'b1;
          end
        end else begin
          finish = 1'b1;
        end
      end
      SCAN: begin
        case (c_q.scan_phase)
          SCAN_READ: begin
            if (valid_q[c_q.set_idx] == '0) begin
              scan_advance = 1'b1;
            end else begin
              tag_ceb_o = 1'b0;
              c_d.scan_phase = SCAN_WAIT;
            end
          end
          SCAN_WAIT: begin
            c_d.scan_phase = SCAN_EVAL;
          end
          SCAN_EVAL: begin
            tag_event = tag_single_q || tag_double_q;
            tag_event_type = tag_double_q ? ECC_DOUBLE : ECC_SINGLE;
            if (tag_double_q) begin
              c_d.cbo_ecc_seen = 1'b1;
            end
            if (tag_single_q) begin
              c_d.scrub_tag = 1'b1;
              c_d.scrub_data = 1'b0;
              c_d.resume = SCAN;
              c_d.state = SCRUB;
            end else if (|dirty_mask) begin
              selected_way = first_way;
              start_victim = 1'b1;
            end else begin
              scan_advance = 1'b1;
            end
          end
          default: begin
            c_d.scan_phase = SCAN_READ;
          end
        endcase
      end
      default: begin
        c_d.state = IDLE;
      end
    endcase

    if (start_victim || begin_refill || begin_zero) begin
      c_d.way = selected_way;
      c_d.bus_started = 1'b0;
      c_d.write_valid = 1'b0;
      c_d.critical_seen = 1'b0;
      c_d.critical_err = 1'b0;
      c_d.response_issued = 1'b0;
      c_d.amo_phase = 1'b0;
      c_d.rf_done = 1'b0;
      c_d.rf_error = 1'b0;
      c_d.new_allocation = !hit;
      modified_tag = clean_tag;
      modified_tag[selected_way * (TAG_WIDTH + 1) +: TAG_WIDTH] =
          tag_of(c_q.req.addr);
      modified_tag[selected_way * (TAG_WIDTH + 1) + TAG_WIDTH] =
          c_q.req.kind inside {REQ_STORE, REQ_SC, REQ_AMO, REQ_CBO};
      c_d.install_tag = encode_tag(modified_tag);
      if (start_victim) begin
        c_d.state = VICTIM_READ;
        c_d.issued = '0;
        c_d.received = '0;
        c_d.repair = '0;
        c_d.victim_base = line_address(
            tag_q[selected_way * (TAG_WIDTH + 1) +: TAG_WIDTH], c_q.set_idx);
        if (reuse_lookup) begin
          line_reuse = 1'b1;
          reuse_way = selected_way;
          reuse_beat = c_q.req.addr[4:3];
          c_d.issued[reuse_beat] = 1'b1;
          c_d.received[reuse_beat] = 1'b1;
          c_d.repair[reuse_beat] = single_q[selected_way];
          data_event = single_q[selected_way] || double_q[selected_way];
          data_event_type = double_q[selected_way] ? ECC_DOUBLE : ECC_SINGLE;
          data_event_way = selected_way;
          data_event_index = {c_q.set_idx, reuse_beat};
          if (double_q[selected_way] && (c_q.req.kind == REQ_CBO)) begin
            c_d.cbo_ecc_seen = 1'b1;
          end
        end
        missing_beat = '0;
        for (int beat_idx = 3; beat_idx >= 0; beat_idx--) begin
          if (!c_d.issued[beat_idx]) begin
            missing_beat = 2'(beat_idx);
          end
        end
        data_ceb_o[selected_way] = 1'b0;
        data_web_o[selected_way] = 1'b1;
        data_addr_o[selected_way] = {c_q.set_idx, missing_beat};
        c_d.issued[missing_beat] = 1'b1;
      end else begin
        valid_write = 1'b1;
        valid_value[selected_way] = 1'b0;
        if (begin_zero) begin
          c_d.state = ZERO_WRITE;
          c_d.zero_count = '0;
        end else begin
          c_d.state = REFILL;
          bus_start = bus_idle;
          c_d.bus_started = bus_start;
        end
      end
    end

    // Stream from the BIU, including D accompanying a Get started in LOOKUP_EVAL.
    if (bus_refill_fire) begin
      c_d.rf_error = c_d.rf_error || bus_error;
      if (bus_beat == LAST_BEAT) begin
        c_d.rf_done = 1'b1;
      end
      if (bus_beat == c_q.req.addr[4:3]) begin
        c_d.critical_seen = 1'b1;
        c_d.critical_err = c_d.rf_error;
        c_d.critical_old = bus_data;
        if (c_q.req.kind == REQ_LOAD) begin
          result_valid_o = 1'b1;
          result_failed_o = c_d.rf_error;
          result_data_o = bus_data;
          c_d.response_issued = 1'b1;
        end else if (c_q.req.kind == REQ_AMO) begin
          c_d.amo_phase = 1'b1;
        end
      end
      if (!c_d.rf_error &&
          !((c_q.req.kind == REQ_AMO) &&
              (bus_beat == c_q.req.addr[4:3]))) begin
        new_data = bus_data;
        if ((c_q.req.kind inside {REQ_STORE, REQ_SC}) &&
            (bus_beat == c_q.req.addr[4:3])) begin
          new_data = merge_bytes(bus_data, c_q.req.data, c_q.req.mask);
        end
        c_d.write_valid = 1'b1;
        c_d.write_code = prim_secded_72_64_enc(new_data);
        c_d.write_addr = {c_q.set_idx, bus_beat};
        c_d.write_last = bus_beat == LAST_BEAT;
      end
    end

    if (scan_advance) begin
      if (c_q.set_idx == INDEX_WIDTH'(SET_COUNT - 1)) begin
        finish = 1'b1;
      end else begin
        c_d.set_idx = c_q.set_idx + 1'b1;
        c_d.state = SCAN;
        c_d.scan_phase = SCAN_READ;
        // A Tag write occupies this edge; otherwise read the next set immediately.
        if (tag_web_o && (valid_q[c_q.set_idx + 1'b1] != '0)) begin
          tag_ceb_o = 1'b0;
          tag_addr_o = c_q.set_idx + 1'b1;
          c_d.scan_phase = SCAN_WAIT;
        end
      end
    end
    if (finish) begin
      c_d.state = IDLE;
      c_d.bus_started = 1'b0;
      c_d.write_valid = 1'b0;
      work_done_o = c_q.req.kind != REQ_CBO;
      finish_cbo = c_q.req.kind == REQ_CBO;
    end
    if (cbo_execute) begin
      c_d.req = '0;
      c_d.req.kind = REQ_CBO;
      c_d.req.addr = executing_addr;
      c_d.set_idx = set_of(executing_addr);
      if (executing_cbo == CBO_INVAL_ALL) begin
        valid_clear_all = 1'b1;
        finish_cbo = 1'b1;
      end else if (executing_cbo == CBO_CLEAN_ALL) begin
        c_d.state = SCAN;
        c_d.set_idx = '0;
        c_d.scan_phase = SCAN_READ;
      end else begin
        do_lookup = 1'b1;
        lookup_req = c_d.req;
      end
    end
    if (req_valid_i && req_ready_o) begin
      do_lookup = 1'b1;
      lookup_req = req_i;
    end
    if (do_lookup) begin
      c_d.req = lookup_req;
      c_d.set_idx = set_of(lookup_req.addr);
      c_d.state = LOOKUP_ECC;
      c_d.response_issued = 1'b0;
      c_d.write_valid = 1'b0;
      c_d.bus_started = 1'b0;
      c_d.rf_done = 1'b0;
      c_d.rf_error = 1'b0;
      c_d.amo_phase = 1'b0;
      tag_ceb_o = 1'b0;
      tag_web_o = 1'b1;
      tag_addr_o = set_of(lookup_req.addr);
      for (int way_idx = 0; way_idx < 4; way_idx++) begin
        data_ceb_o[way_idx] = 1'b0;
        data_web_o[way_idx] = 1'b1;
        data_addr_o[way_idx] = {
          set_of(lookup_req.addr),
          lookup_req.addr[4:3]
        };
      end
    end
    if (finish_cbo) begin
      c_d.cbo_active = 1'b0;
      c_d.state = IDLE;
    end
  end

  always_ff @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
      c_q <= '0;
      c_q.cbo_armed <= 1'b1;
      lfsr_q <= 16'h0001;
      tag_q <= '0;
      tag_single_q <= 1'b0;
      tag_double_q <= 1'b0;
      data_q <= '0;
      single_q <= '0;
      double_q <= '0;
      rd_tag_q <= 1'b0;
      rd_data_q <= '0;
      rd_set_q <= '0;
      rd_beat_q <= '0;
      rd_way_q <= '0;
      rd_victim_q <= 1'b0;
      victim_event_q <= 1'b0;
      victim_single_q <= 1'b0;
      victim_double_q <= 1'b0;
      victim_event_index_q <= '0;
      victim_event_way_q <= '0;
      line_q <= '0;
      cbo_ack_o <= 1'b0;
      cbo_bus_err_o <= 1'b0;
      cbo_ecc_err_o <= 1'b0;
      tag_err_valid_o <= 1'b0;
      data_err_valid_o <= 1'b0;
      tag_err_type_o <= '0;
      data_err_type_o <= '0;
      tag_err_addr_o <= '0;
      data_err_addr_o <= '0;
      for (int set_idx = 0; set_idx < SET_COUNT; set_idx++) begin
        valid_q[set_idx] <= '0;
      end
    end else begin
      c_q <= c_d;
      if (valid_clear_all) begin
        for (int set_idx = 0; set_idx < SET_COUNT; set_idx++) begin
          valid_q[set_idx] <= '0;
        end
      end else if (valid_write) begin
        valid_q[valid_index] <= valid_value;
      end
      if (advance_lfsr) begin
        lfsr_q <= lfsr_next(lfsr_q);
      end

      rd_tag_q <= !tag_ceb_o && tag_web_o;
      rd_data_q <= (~data_ceb_o) & data_web_o;
      if (!tag_ceb_o && tag_web_o) begin
        rd_set_q <= tag_addr_o;
      end
      rd_victim_q <= 1'b0;
      for (int way_idx = 0; way_idx < 4; way_idx++) begin
        if (!data_ceb_o[way_idx] && data_web_o[way_idx]) begin
          rd_beat_q <= data_addr_o[way_idx][1:0];
          rd_way_q <= 2'(way_idx);
          rd_victim_q <= start_victim || (c_q.state == VICTIM_READ);
        end
      end

      if (rd_tag_q) begin
        tag_q <= (valid_q[rd_set_q] != '0) ? tag_dec : '0;
        tag_single_q <= (valid_q[rd_set_q] != '0) && tag_single_dec;
        tag_double_q <= (valid_q[rd_set_q] != '0) && tag_double_dec;
      end
      for (int way_idx = 0; way_idx < 4; way_idx++) begin
        if (rd_data_q[way_idx]) begin
          data_q[way_idx] <= data_dec[way_idx];
          single_q[way_idx] <= single_dec[way_idx];
          double_q[way_idx] <= double_dec[way_idx];
        end
      end
      if (tag_event) begin
        tag_single_q <= 1'b0;
        tag_double_q <= 1'b0;
      end
      if (data_event && !victim_event_q) begin
        single_q[data_event_way] <= 1'b0;
        double_q[data_event_way] <= 1'b0;
      end
      if (!tag_ceb_o && !tag_web_o) begin
        tag_q <= tag_raw_write;
        tag_single_q <= 1'b0;
        tag_double_q <= 1'b0;
      end
      if ((c_q.state == SCRUB) && c_q.scrub_data) begin
        single_q[c_q.way] <= 1'b0;
        double_q[c_q.way] <= 1'b0;
      end
      if (line_reuse) begin
        line_q[reuse_beat] <= data_q[reuse_way];
      end

      victim_event_q <= rd_victim_q;
      if (rd_victim_q) begin
        line_q[rd_beat_q] <= data_dec[rd_way_q];
        victim_single_q <= single_dec[rd_way_q];
        victim_double_q <= double_dec[rd_way_q];
        victim_event_index_q <= {c_q.set_idx, rd_beat_q};
        victim_event_way_q <= rd_way_q;
      end

      tag_err_valid_o <= check_en_i && tag_event;
      tag_err_addr_o <= (check_en_i && tag_event) ?
          18'(tag_event_index) : 18'b0;
      tag_err_type_o <= (check_en_i && tag_event) ? tag_event_type : 2'b0;
      data_err_valid_o <= check_en_i && data_event;
      data_err_addr_o <= (check_en_i && data_event) ?
          18'({data_event_way, data_event_index}) : 18'b0;
      data_err_type_o <= (check_en_i && data_event) ? data_event_type : 2'b0;
      cbo_ack_o <= finish_cbo;
      cbo_bus_err_o <= finish_cbo && c_d.cbo_bus_seen;
      cbo_ecc_err_o <= finish_cbo && c_d.cbo_ecc_seen;
    end
  end

`ifndef SYNTHESIS
  initial begin
    assert (`dCacheSize inside {16, 32, 64, 128})
      else $fatal(1, "Unsupported DCache capacity");
    assert (`dcDataRamWidth == 72 && `dcDataWmWidth == 9)
      else $fatal(1, "This revision requires ECC configuration");
  end

  always_ff @(posedge clk_i) begin
    if (rst_n_i) begin
      assert (!(bus_start && !bus_idle))
        else $fatal(1, "DC restarted BIU");
      assert (!(cbo_accept_o && (c_q.state != IDLE)))
        else $fatal(1, "CBO accepted while busy");
      assert (!(cbo_req_i && !drained_i))
        else $fatal(1, "CBO request presented before Store Buffer drained");
      if ((c_q.state == LOOKUP_EVAL) && !tag_double_q) begin
        assert ($onehot0(hit_mask))
          else $fatal(1, "multiple cache hits");
      end
    end
  end
`endif

endmodule

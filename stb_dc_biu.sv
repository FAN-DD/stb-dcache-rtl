`include "uncore_def.sv"

module stb_dc_biu
  import uncore_pkg::*;
(
  input  logic                      clk_i,
  input  logic                      rst_n_i,
  input  logic                      start_i,
  input  logic                      put_i,
  input  logic [31:0]               base_i,
  input  wire  [3:0][63:0]          line_i,
  output logic                      idle_o,
  input  logic                      refill_ready_i,
  output logic                      refill_fire_o,
  output logic [1:0]                refill_beat_o,
  output logic [63:0]               refill_data_o,
  output logic                      refill_error_o,
  output logic                      done_o,
  output logic                      failed_o,
  output logic                      a_valid_o,
  input  logic                      a_ready_i,
  output Slv_TL_A_Chan_t            a_o,
  input  logic                      d_valid_i,
  output logic                      d_ready_o,
  input  wire  Slv_TL_D_Chan_t      d_i
);

  localparam logic [2:0] LINE_SIZE = 3'd5;
  localparam logic [2:0] LINE_BEATS = 3'd4;

  logic busy_q;
  logic put_q;
  logic ack_q;
  logic error_q;
  logic [2:0] a_count_q;
  logic [2:0] d_count_q;
  logic [31:0] base_q;

  logic active;
  logic is_put;
  logic a_fire;
  logic d_fire;
  logic ack_next;
  logic error_next;
  logic [2:0] a_count;
  logic [2:0] d_count;
  logic [2:0] a_count_next;
  logic [2:0] d_count_next;

  assign idle_o = !busy_q;

  always_comb begin
    active = busy_q || start_i;
    is_put = busy_q ? put_q : put_i;
    a_count = busy_q ? a_count_q : '0;
    d_count = busy_q ? d_count_q : '0;

    a_o = '0;
    a_o.tl_a_opcode = is_put ? `PutFullData : `Get;
    a_o.tl_a_size = LINE_SIZE;
    a_o.tl_a_source = {`DC_MASID, 1'b0};
    a_o.tl_a_addr = busy_q ? base_q : base_i;
    a_o.tl_a_mask = 8'hff;
    a_o.tl_a_data = is_put ? line_i[a_count[1:0]] : 64'b0;

    a_valid_o = active &&
        (is_put ? (a_count < LINE_BEATS) : (a_count == '0));
    a_fire = a_valid_o && a_ready_i;

    // The first D response is accepted no earlier than the cycle after the
    // first A handshake.  This also removes an A-ready to D-ready path.
    d_ready_o = busy_q && (a_count_q != '0) &&
        (is_put ? !(busy_q && ack_q) :
            ((d_count < LINE_BEATS) && refill_ready_i));
    d_fire = d_valid_i && d_ready_o;

    a_count_next = a_count + 3'(a_fire);
    d_count_next = d_count + 3'(d_fire && !is_put);
    ack_next = (busy_q && ack_q) || (d_fire && is_put);
    error_next = (busy_q && error_q) || (d_fire && d_i.tl_d_error);

    done_o = active && (is_put ?
        ((a_count_next == LINE_BEATS) && ack_next) :
        (d_count_next == LINE_BEATS));
    failed_o = error_next;
    refill_fire_o = d_fire && !is_put;
    refill_beat_o = d_count[1:0];
    refill_data_o = d_i.tl_d_data;
    refill_error_o = d_i.tl_d_error;
  end

  always_ff @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
      busy_q <= 1'b0;
      put_q <= 1'b0;
      ack_q <= 1'b0;
      error_q <= 1'b0;
      a_count_q <= '0;
      d_count_q <= '0;
      base_q <= '0;
    end else if (active) begin
      busy_q <= !done_o;
      if (!busy_q) begin
        put_q <= put_i;
        base_q <= base_i;
      end
      a_count_q <= a_count_next;
      d_count_q <= d_count_next;
      ack_q <= ack_next;
      error_q <= error_next;
    end
  end

`ifndef SYNTHESIS
  always_ff @(posedge clk_i) begin
    if (rst_n_i) begin
      if (start_i && busy_q) begin
        $fatal(1, "BIU restart while busy");
      end
      if (d_fire) begin
        assert (a_count_q != '0)
          else $fatal(1, "BIU D response before a registered A handshake");
        assert (d_i.tl_d_source == {`DC_MASID, 1'b0} &&
                    d_i.tl_d_size == LINE_SIZE)
          else $fatal(1, "BIU response metadata");
        assert (d_i.tl_d_opcode == (is_put ? `AccessAck : `AccessAckData))
          else $fatal(1, "BIU response opcode");
      end
    end
  end
`endif

endmodule

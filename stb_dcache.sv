`include "uncore_def.sv"
`include "dcache_def.sv"

module stb_dcache
  import uncore_pkg::*;
  import ecc_pkg::*;
  import stb_dc_pkg::*;
  import kratos_pkg::*;
#(
  parameter int unsigned STB_DEPTH = 4
) (
  input  logic                              clk_i,
  input  logic                              rst_n_i,

  input  wire  Slv_TL_A_Chan_t              tl_slv_a_ch_i,
  input  logic                              tl_slv_a_vld_i,
  output logic                              tl_slv_a_rdy_o,

  output logic                              stb_drained_out,

  output Slv_TL_D_Chan_t                    tl_slv_d_ch_o,
  input  logic                              tl_slv_d_rdy_i,
  output logic                              tl_slv_d_vld_o,

  input  logic                              test_mode_i,
  output logic                              dc_fsm_busy,

  output logic                              dc_tl_mst_a_vld_o,
  input  logic                              dc_tl_mst_a_rdy_i,
  output Slv_TL_A_Chan_t                    dc_tl_mst_a_ch_o,
  input  logic                              dc_tl_mst_d_vld_i,
  output logic                              dc_tl_mst_d_rdy_o,
  input  wire  Slv_TL_D_Chan_t              dc_tl_mst_d_ch_i,

  input  logic [`MasAddrWidth-1:0]          cbo_addr_i,
  input  cbo_type_e                         cbo_type_i,
  input  logic                              cbo_req_i,
  output logic                              cbo_ack_o,
  output logic                              cbo_bus_err_o,
  output logic                              cbo_ecc_err_o,

`ifdef HAS_DCache_Check
  input  logic                              check_en_i,
  output logic                              tag_err_vld_o,
  output logic [17:0]                       tag_err_addr_o,
  output logic [1:0]                        tag_err_type_o,
  output logic                              data_err_vld_o,
  output logic [17:0]                       data_err_addr_o,
  output logic [1:0]                        data_err_type_o,
`endif

  output logic [`dcTagIdxWidth-1:0]         tagram_addr_o,
  output logic [`dcTagRamWidth-1:0]         tagram_wdata_o,
  input  logic [`dcTagRamWidth-1:0]         tagram_rdata_i,
  output logic                              tagram_CEB_o,
  output logic                              tagram_WEB_o,
  output logic [`dcTagRamWidth-1:0]         tagram_wm_o,

  output logic [`dcDataIdxWidth-1:0]        dataram_0_addr_o,
  output logic [`dcDataRamWidth-1:0]        dataram_0_wdata_o,
  input  logic [`dcDataRamWidth-1:0]        dataram_0_rdata_i,
  output logic                              dataram_0_CEB_o,
  output logic                              dataram_0_WEB_o,
  output logic [`dcDataWmWidth-1:0]         dataram_0_wm_o,

  output logic [`dcDataIdxWidth-1:0]        dataram_1_addr_o,
  output logic [`dcDataRamWidth-1:0]        dataram_1_wdata_o,
  input  logic [`dcDataRamWidth-1:0]        dataram_1_rdata_i,
  output logic                              dataram_1_CEB_o,
  output logic                              dataram_1_WEB_o,
  output logic [`dcDataWmWidth-1:0]         dataram_1_wm_o,

  output logic [`dcDataIdxWidth-1:0]        dataram_2_addr_o,
  output logic [`dcDataRamWidth-1:0]        dataram_2_wdata_o,
  input  logic [`dcDataRamWidth-1:0]        dataram_2_rdata_i,
  output logic                              dataram_2_CEB_o,
  output logic                              dataram_2_WEB_o,
  output logic [`dcDataWmWidth-1:0]         dataram_2_wm_o,

  output logic [`dcDataIdxWidth-1:0]        dataram_3_addr_o,
  output logic [`dcDataRamWidth-1:0]        dataram_3_wdata_o,
  input  logic [`dcDataRamWidth-1:0]        dataram_3_rdata_i,
  output logic                              dataram_3_CEB_o,
  output logic                              dataram_3_WEB_o,
  output logic [`dcDataWmWidth-1:0]         dataram_3_wm_o,
  input  logic                              lr_invalid
);

  dc_req_t dc_req;
  dc_req_t pending_req;
  logic dc_valid;
  logic dc_ready;
  logic pending_valid;
  logic result_valid;
  logic result_direct;
  logic result_failed;
  logic work_done;
  logic lr_set;
  logic [63:0] result_data;
  logic front_block;
  logic front_quiet;
  logic cbo_accept;
  logic check_enabled;
  logic tag_err_valid;
  logic data_err_valid;
  logic [17:0] tag_err_addr;
  logic [17:0] data_err_addr;
  logic [1:0] tag_err_type;
  logic [1:0] data_err_type;
  logic [3:0][`dcDataIdxWidth-1:0] ram_addr;
  logic [3:0][71:0] ram_wdata;
  logic [3:0][71:0] ram_rdata;
  logic [3:0][8:0] ram_wm;
  logic [3:0] ram_ceb;
  logic [3:0] ram_web;

  assign ram_rdata = {
    dataram_3_rdata_i,
    dataram_2_rdata_i,
    dataram_1_rdata_i,
    dataram_0_rdata_i
  };
  assign {
    dataram_3_addr_o,
    dataram_2_addr_o,
    dataram_1_addr_o,
    dataram_0_addr_o
  } = ram_addr;
  assign {
    dataram_3_wdata_o,
    dataram_2_wdata_o,
    dataram_1_wdata_o,
    dataram_0_wdata_o
  } = ram_wdata;
  assign {
    dataram_3_wm_o,
    dataram_2_wm_o,
    dataram_1_wm_o,
    dataram_0_wm_o
  } = ram_wm;
  assign {
    dataram_3_CEB_o,
    dataram_2_CEB_o,
    dataram_1_CEB_o,
    dataram_0_CEB_o
  } = ram_ceb;
  assign {
    dataram_3_WEB_o,
    dataram_2_WEB_o,
    dataram_1_WEB_o,
    dataram_0_WEB_o
  } = ram_web;
  assign tagram_wm_o = '1;

`ifdef HAS_DCache_Check
  assign check_enabled = check_en_i;
  assign tag_err_vld_o = tag_err_valid;
  assign data_err_vld_o = data_err_valid;
  assign tag_err_addr_o = tag_err_addr;
  assign data_err_addr_o = data_err_addr;
  assign tag_err_type_o = tag_err_type;
  assign data_err_type_o = data_err_type;
`else
  assign check_enabled = 1'b0;
`endif

  stb_dc_front #(
    .DEPTH(STB_DEPTH)
  ) u_front (
    .clk_i,
    .rst_n_i,
    .a_i(tl_slv_a_ch_i),
    .a_valid_i(tl_slv_a_vld_i),
    .a_ready_o(tl_slv_a_rdy_o),
    .d_o(tl_slv_d_ch_o),
    .d_valid_o(tl_slv_d_vld_o),
    .block_i(front_block),
    .quiescent_o(front_quiet),
    .drained_o(stb_drained_out),
    .req_o(dc_req),
    .req_valid_o(dc_valid),
    .req_ready_i(dc_ready),
    .pending_valid_i(pending_valid),
    .pending_i(pending_req),
    .result_valid_i(result_valid),
    .result_direct_i(result_direct),
    .result_failed_i(result_failed),
    .result_data_i(result_data),
    .work_done_i(work_done),
    .lr_set_i(lr_set),
    .cbo_accept_i(cbo_accept),
    .lr_invalid_i(lr_invalid)
  );

  stb_dc_core u_core (
    .clk_i,
    .rst_n_i,
    .req_i(dc_req),
    .req_valid_i(dc_valid),
    .req_ready_o(dc_ready),
    .pending_valid_o(pending_valid),
    .pending_o(pending_req),
    .result_valid_o(result_valid),
    .result_direct_o(result_direct),
    .result_failed_o(result_failed),
    .result_data_o(result_data),
    .work_done_o(work_done),
    .lr_set_o(lr_set),
    .front_quiet_i(front_quiet),
    .drained_i(stb_drained_out),
    .cbo_req_i,
    .cbo_type_i,
    .cbo_addr_i,
    .cbo_accept_o(cbo_accept),
    .front_block_o(front_block),
    .cbo_ack_o,
    .cbo_bus_err_o,
    .cbo_ecc_err_o,
    .busy_o(dc_fsm_busy),
    .check_en_i(check_enabled),
    .tag_err_valid_o(tag_err_valid),
    .data_err_valid_o(data_err_valid),
    .tag_err_addr_o(tag_err_addr),
    .data_err_addr_o(data_err_addr),
    .tag_err_type_o(tag_err_type),
    .data_err_type_o(data_err_type),
    .tag_addr_o(tagram_addr_o),
    .tag_wdata_o(tagram_wdata_o),
    .tag_rdata_i(tagram_rdata_i),
    .tag_ceb_o(tagram_CEB_o),
    .tag_web_o(tagram_WEB_o),
    .data_addr_o(ram_addr),
    .data_wdata_o(ram_wdata),
    .data_rdata_i(ram_rdata),
    .data_ceb_o(ram_ceb),
    .data_web_o(ram_web),
    .data_wm_o(ram_wm),
    .bus_a_valid_o(dc_tl_mst_a_vld_o),
    .bus_a_ready_i(dc_tl_mst_a_rdy_i),
    .bus_a_o(dc_tl_mst_a_ch_o),
    .bus_d_valid_i(dc_tl_mst_d_vld_i),
    .bus_d_ready_o(dc_tl_mst_d_rdy_o),
    .bus_d_i(dc_tl_mst_d_ch_i)
  );

  // test_mode_i is reserved for technology ICG integration. The portable RTL
  // intentionally uses clk_i with register enables until the target ICG cell
  // and DFT connection are defined.

`ifndef SYNTHESIS
  always_ff @(posedge clk_i) begin
    if (rst_n_i) begin
      assert (tl_slv_d_rdy_i === 1'b1)
        else $fatal(1, "LSU D ready must be tied high");
    end
  end
`endif

endmodule

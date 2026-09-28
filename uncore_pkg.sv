`include "uncore_def.sv"

package uncore_pkg;

  typedef struct packed {
    logic [2:0] tl_a_opcode;
    logic [2:0] tl_a_param;
    logic [`MasSizeW-1:0] tl_a_size;
    logic [`SlvIdWidth-1:0] tl_a_source;
    logic [`MasDataWidth/8-1:0] tl_a_mask;
    logic [`MasAddrWidth-1:0] tl_a_addr;
    logic [`MasDataWidth-1:0] tl_a_data;
  } Slv_TL_A_Chan_t;

  typedef struct packed {
    logic [2:0] tl_d_opcode;
    logic [2:0] tl_d_param;
    logic [`MasSizeW-1:0] tl_d_size;
    logic [`SlvIdWidth-1:0] tl_d_source;
    logic [`MasDataWidth-1:0] tl_d_data;
    logic tl_d_error;
  } Slv_TL_D_Chan_t;

endpackage

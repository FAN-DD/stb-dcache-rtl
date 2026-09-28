package stb_dc_pkg;

  localparam logic [2:0] TL_PARAM_NORMAL = 3'd0;
  localparam logic [2:0] TL_PARAM_ATOMIC = 3'd1;
  localparam logic [2:0] TL_SIZE_WORD = 3'd2;
  localparam logic [2:0] TL_SIZE_DOUBLEWORD = 3'd3;

  localparam logic [2:0] AMO_OPCODE_ARITHMETIC = 3'd2;
  localparam logic [2:0] AMO_PARAM_MIN = 3'd0;
  localparam logic [2:0] AMO_PARAM_MAX = 3'd1;
  localparam logic [2:0] AMO_PARAM_MINU = 3'd2;
  localparam logic [2:0] AMO_PARAM_MAXU = 3'd3;
  localparam logic [2:0] AMO_PARAM_ADD = 3'd4;
  localparam logic [2:0] AMO_PARAM_XOR = 3'd0;
  localparam logic [2:0] AMO_PARAM_OR = 3'd1;
  localparam logic [2:0] AMO_PARAM_AND = 3'd2;
  localparam logic [2:0] AMO_PARAM_SWAP = 3'd3;

  typedef enum logic [2:0] {
    REQ_LOAD,
    REQ_STORE,
    REQ_LR,
    REQ_SC,
    REQ_AMO,
    REQ_CBO
  } req_kind_e;

  typedef struct packed {
    req_kind_e kind;
    logic [31:0] addr;
    logic [63:0] data;
    logic [7:0] mask;
    logic [2:0] opcode;
    logic [2:0] param;
    logic [2:0] size;
  } dc_req_t;

  function automatic logic [63:0] merge_bytes(
    input logic [63:0] old_data,
    input logic [63:0] new_data,
    input logic [7:0] mask
  );
    logic [63:0] result;

    for (int byte_idx = 0; byte_idx < 8; byte_idx++) begin
      result[byte_idx * 8 +: 8] = mask[byte_idx] ?
          new_data[byte_idx * 8 +: 8] : old_data[byte_idx * 8 +: 8];
    end
    return result;
  endfunction

  function automatic logic [63:0] lane_result(
    input logic [63:0] data,
    input logic lane
  );
    return lane ? {data[63:32], 32'b0} : {32'b0, data[31:0]};
  endfunction

  function automatic logic [63:0] amo_result(
    input logic [63:0] old_data,
    input logic [63:0] operand,
    input logic lane,
    input logic [2:0] opcode,
    input logic [2:0] param
  );
    logic [31:0] lhs;
    logic [31:0] rhs;
    logic [31:0] result;

    lhs = lane ? old_data[63:32] : old_data[31:0];
    rhs = lane ? operand[63:32] : operand[31:0];
    result = rhs;

    if (opcode == AMO_OPCODE_ARITHMETIC) begin
      case (param)
        AMO_PARAM_MIN: result = ($signed(lhs) < $signed(rhs)) ? lhs : rhs;
        AMO_PARAM_MAX: result = ($signed(lhs) > $signed(rhs)) ? lhs : rhs;
        AMO_PARAM_MINU: result = (lhs < rhs) ? lhs : rhs;
        AMO_PARAM_MAXU: result = (lhs > rhs) ? lhs : rhs;
        AMO_PARAM_ADD: result = lhs + rhs;
        default: result = rhs;
      endcase
    end else begin
      case (param)
        AMO_PARAM_XOR: result = lhs ^ rhs;
        AMO_PARAM_OR: result = lhs | rhs;
        AMO_PARAM_AND: result = lhs & rhs;
        AMO_PARAM_SWAP: result = rhs;
        default: result = rhs;
      endcase
    end

    return lane ? {result, old_data[31:0]} : {old_data[63:32], result};
  endfunction

  // Right-shifting Galois LFSR, nonzero seed; 65535-state period.
  function automatic logic [15:0] lfsr_next(input logic [15:0] value);
    return (value >> 1) ^ (value[0] ? 16'hb400 : 16'h0000);
  endfunction

endpackage

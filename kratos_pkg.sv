package kratos_pkg;

  typedef enum logic [2:0] {
    CBO_INVAL     = 3'b000,
    CBO_CLEAN     = 3'b001,
    CBO_FLUSH     = 3'b010,
    CBO_ZERO      = 3'b011,
    CBO_CLEAN_ALL = 3'b100,
    CBO_INVAL_ALL = 3'b101
  } cbo_type_e;

endpackage

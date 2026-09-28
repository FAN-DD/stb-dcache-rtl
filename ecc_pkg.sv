package ecc_pkg;

  function automatic int unsigned get_parity_width(input int unsigned data_width);
    int unsigned parity_width = 2;

    while (unsigned'(2 ** parity_width) < parity_width + data_width + 1) begin
      parity_width++;
    end
    return parity_width;
  endfunction

  function automatic int unsigned get_cw_width(input int unsigned data_width);
    return data_width + get_parity_width(data_width);
  endfunction

endpackage

module ecc_codec
  import prim_secded_pkg::*;
  import ecc_pkg::*;
#(
  parameter int unsigned ECC_DATA_WIDTH = 72,
  parameter int unsigned RAW_DATA_WIDTH = 64
)(
  // Encoder ports.
  input  logic [RAW_DATA_WIDTH-1:0] raw_encode_data,
  output logic [ECC_DATA_WIDTH-1:0] encode_ecc_data,

  // Decoder ports.
  input  logic [ECC_DATA_WIDTH-1:0] ecc_decode_data,
  output logic [RAW_DATA_WIDTH-1:0] decode_raw_data,
  output logic                      ecc_single_err,
  output logic                      ecc_double_err
);

// This repetitive generate table is a mechanical adapter to the generated
// lowRISC prim_secded_pkg functions. Keep each width as a direct mapping so
// synthesis sees only the selected encoder and decoder.
case (RAW_DATA_WIDTH)
2: begin
  secded_6_2_t data_dec_t;
  assign encode_ecc_data = prim_secded_6_2_enc(raw_encode_data);
  assign data_dec_t = prim_secded_6_2_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
3: begin
  secded_7_3_t data_dec_t;
  assign encode_ecc_data = prim_secded_7_3_enc(raw_encode_data);
  assign data_dec_t = prim_secded_7_3_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
4: begin
  secded_8_4_t data_dec_t;
  assign encode_ecc_data = prim_secded_8_4_enc(raw_encode_data);
  assign data_dec_t = prim_secded_8_4_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
5: begin
  secded_10_5_t data_dec_t;
  assign encode_ecc_data = prim_secded_10_5_enc(raw_encode_data);
  assign data_dec_t = prim_secded_10_5_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
6: begin
  secded_11_6_t data_dec_t;
  assign encode_ecc_data = prim_secded_11_6_enc(raw_encode_data);
  assign data_dec_t = prim_secded_11_6_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
7: begin
  secded_12_7_t data_dec_t;
  assign encode_ecc_data = prim_secded_12_7_enc(raw_encode_data);
  assign data_dec_t = prim_secded_12_7_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
8: begin
  secded_13_8_t data_dec_t;
  assign encode_ecc_data = prim_secded_13_8_enc(raw_encode_data);
  assign data_dec_t = prim_secded_13_8_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
9: begin
  secded_14_9_t data_dec_t;
  assign encode_ecc_data = prim_secded_14_9_enc(raw_encode_data);
  assign data_dec_t = prim_secded_14_9_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
10: begin
  secded_15_10_t data_dec_t;
  assign encode_ecc_data = prim_secded_15_10_enc(raw_encode_data);
  assign data_dec_t = prim_secded_15_10_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
11: begin
  secded_16_11_t data_dec_t;
  assign encode_ecc_data = prim_secded_16_11_enc(raw_encode_data);
  assign data_dec_t = prim_secded_16_11_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
12: begin
  secded_18_12_t data_dec_t;
  assign encode_ecc_data = prim_secded_18_12_enc(raw_encode_data);
  assign data_dec_t = prim_secded_18_12_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
13: begin
  secded_19_13_t data_dec_t;
  assign encode_ecc_data = prim_secded_19_13_enc(raw_encode_data);
  assign data_dec_t = prim_secded_19_13_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
14: begin
  secded_20_14_t data_dec_t;
  assign encode_ecc_data = prim_secded_20_14_enc(raw_encode_data);
  assign data_dec_t = prim_secded_20_14_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
15: begin
  secded_21_15_t data_dec_t;
  assign encode_ecc_data = prim_secded_21_15_enc(raw_encode_data);
  assign data_dec_t = prim_secded_21_15_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
16: begin
  secded_22_16_t data_dec_t;
  assign encode_ecc_data = prim_secded_22_16_enc(raw_encode_data);
  assign data_dec_t = prim_secded_22_16_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
17: begin
  secded_23_17_t data_dec_t;
  assign encode_ecc_data = prim_secded_23_17_enc(raw_encode_data);
  assign data_dec_t = prim_secded_23_17_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
18: begin
  secded_24_18_t data_dec_t;
  assign encode_ecc_data = prim_secded_24_18_enc(raw_encode_data);
  assign data_dec_t = prim_secded_24_18_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
19: begin
  secded_25_19_t data_dec_t;
  assign encode_ecc_data = prim_secded_25_19_enc(raw_encode_data);
  assign data_dec_t = prim_secded_25_19_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
20: begin
  secded_26_20_t data_dec_t;
  assign encode_ecc_data = prim_secded_26_20_enc(raw_encode_data);
  assign data_dec_t = prim_secded_26_20_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
21: begin
  secded_27_21_t data_dec_t;
  assign encode_ecc_data = prim_secded_27_21_enc(raw_encode_data);
  assign data_dec_t = prim_secded_27_21_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
22: begin
  secded_28_22_t data_dec_t;
  assign encode_ecc_data = prim_secded_28_22_enc(raw_encode_data);
  assign data_dec_t = prim_secded_28_22_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
23: begin
  secded_29_23_t data_dec_t;
  assign encode_ecc_data = prim_secded_29_23_enc(raw_encode_data);
  assign data_dec_t = prim_secded_29_23_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
24: begin
  secded_30_24_t data_dec_t;
  assign encode_ecc_data = prim_secded_30_24_enc(raw_encode_data);
  assign data_dec_t = prim_secded_30_24_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
25: begin
  secded_31_25_t data_dec_t;
  assign encode_ecc_data = prim_secded_31_25_enc(raw_encode_data);
  assign data_dec_t = prim_secded_31_25_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
26: begin
  secded_32_26_t data_dec_t;
  assign encode_ecc_data = prim_secded_32_26_enc(raw_encode_data);
  assign data_dec_t = prim_secded_32_26_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
27: begin
  secded_34_27_t data_dec_t;
  assign encode_ecc_data = prim_secded_34_27_enc(raw_encode_data);
  assign data_dec_t = prim_secded_34_27_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
28: begin
  secded_35_28_t data_dec_t;
  assign encode_ecc_data = prim_secded_35_28_enc(raw_encode_data);
  assign data_dec_t = prim_secded_35_28_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
29: begin
  secded_36_29_t data_dec_t;
  assign encode_ecc_data = prim_secded_36_29_enc(raw_encode_data);
  assign data_dec_t = prim_secded_36_29_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
30: begin
  secded_37_30_t data_dec_t;
  assign encode_ecc_data = prim_secded_37_30_enc(raw_encode_data);
  assign data_dec_t = prim_secded_37_30_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
31: begin
  secded_38_31_t data_dec_t;
  assign encode_ecc_data = prim_secded_38_31_enc(raw_encode_data);
  assign data_dec_t = prim_secded_38_31_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
32: begin
  secded_39_32_t data_dec_t;
  assign encode_ecc_data = prim_secded_39_32_enc(raw_encode_data);
  assign data_dec_t = prim_secded_39_32_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
33: begin
  secded_40_33_t data_dec_t;
  assign encode_ecc_data = prim_secded_40_33_enc(raw_encode_data);
  assign data_dec_t = prim_secded_40_33_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
34: begin
  secded_41_34_t data_dec_t;
  assign encode_ecc_data = prim_secded_41_34_enc(raw_encode_data);
  assign data_dec_t = prim_secded_41_34_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
35: begin
  secded_42_35_t data_dec_t;
  assign encode_ecc_data = prim_secded_42_35_enc(raw_encode_data);
  assign data_dec_t = prim_secded_42_35_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
36: begin
  secded_43_36_t data_dec_t;
  assign encode_ecc_data = prim_secded_43_36_enc(raw_encode_data);
  assign data_dec_t = prim_secded_43_36_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
37: begin
  secded_44_37_t data_dec_t;
  assign encode_ecc_data = prim_secded_44_37_enc(raw_encode_data);
  assign data_dec_t = prim_secded_44_37_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
38: begin
  secded_45_38_t data_dec_t;
  assign encode_ecc_data = prim_secded_45_38_enc(raw_encode_data);
  assign data_dec_t = prim_secded_45_38_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
39: begin
  secded_46_39_t data_dec_t;
  assign encode_ecc_data = prim_secded_46_39_enc(raw_encode_data);
  assign data_dec_t = prim_secded_46_39_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
40: begin
  secded_47_40_t data_dec_t;
  assign encode_ecc_data = prim_secded_47_40_enc(raw_encode_data);
  assign data_dec_t = prim_secded_47_40_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
41: begin
  secded_48_41_t data_dec_t;
  assign encode_ecc_data = prim_secded_48_41_enc(raw_encode_data);
  assign data_dec_t = prim_secded_48_41_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
42: begin
  secded_49_42_t data_dec_t;
  assign encode_ecc_data = prim_secded_49_42_enc(raw_encode_data);
  assign data_dec_t = prim_secded_49_42_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
43: begin
  secded_50_43_t data_dec_t;
  assign encode_ecc_data = prim_secded_50_43_enc(raw_encode_data);
  assign data_dec_t = prim_secded_50_43_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
44: begin
  secded_51_44_t data_dec_t;
  assign encode_ecc_data = prim_secded_51_44_enc(raw_encode_data);
  assign data_dec_t = prim_secded_51_44_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
45: begin
  secded_52_45_t data_dec_t;
  assign encode_ecc_data = prim_secded_52_45_enc(raw_encode_data);
  assign data_dec_t = prim_secded_52_45_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
46: begin
  secded_53_46_t data_dec_t;
  assign encode_ecc_data = prim_secded_53_46_enc(raw_encode_data);
  assign data_dec_t = prim_secded_53_46_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
47: begin
  secded_54_47_t data_dec_t;
  assign encode_ecc_data = prim_secded_54_47_enc(raw_encode_data);
  assign data_dec_t = prim_secded_54_47_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
48: begin
  secded_55_48_t data_dec_t;
  assign encode_ecc_data = prim_secded_55_48_enc(raw_encode_data);
  assign data_dec_t = prim_secded_55_48_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
49: begin
  secded_56_49_t data_dec_t;
  assign encode_ecc_data = prim_secded_56_49_enc(raw_encode_data);
  assign data_dec_t = prim_secded_56_49_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
50: begin
  secded_57_50_t data_dec_t;
  assign encode_ecc_data = prim_secded_57_50_enc(raw_encode_data);
  assign data_dec_t = prim_secded_57_50_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
51: begin
  secded_58_51_t data_dec_t;
  assign encode_ecc_data = prim_secded_58_51_enc(raw_encode_data);
  assign data_dec_t = prim_secded_58_51_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
52: begin
  secded_59_52_t data_dec_t;
  assign encode_ecc_data = prim_secded_59_52_enc(raw_encode_data);
  assign data_dec_t = prim_secded_59_52_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
53: begin
  secded_60_53_t data_dec_t;
  assign encode_ecc_data = prim_secded_60_53_enc(raw_encode_data);
  assign data_dec_t = prim_secded_60_53_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
54: begin
  secded_61_54_t data_dec_t;
  assign encode_ecc_data = prim_secded_61_54_enc(raw_encode_data);
  assign data_dec_t = prim_secded_61_54_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
55: begin
  secded_62_55_t data_dec_t;
  assign encode_ecc_data = prim_secded_62_55_enc(raw_encode_data);
  assign data_dec_t = prim_secded_62_55_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
56: begin
  secded_63_56_t data_dec_t;
  assign encode_ecc_data = prim_secded_63_56_enc(raw_encode_data);
  assign data_dec_t = prim_secded_63_56_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
57: begin
  secded_64_57_t data_dec_t;
  assign encode_ecc_data = prim_secded_64_57_enc(raw_encode_data);
  assign data_dec_t = prim_secded_64_57_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
58: begin
  secded_66_58_t data_dec_t;
  assign encode_ecc_data = prim_secded_66_58_enc(raw_encode_data);
  assign data_dec_t = prim_secded_66_58_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
59: begin
  secded_67_59_t data_dec_t;
  assign encode_ecc_data = prim_secded_67_59_enc(raw_encode_data);
  assign data_dec_t = prim_secded_67_59_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
60: begin
  secded_68_60_t data_dec_t;
  assign encode_ecc_data = prim_secded_68_60_enc(raw_encode_data);
  assign data_dec_t = prim_secded_68_60_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
61: begin
  secded_69_61_t data_dec_t;
  assign encode_ecc_data = prim_secded_69_61_enc(raw_encode_data);
  assign data_dec_t = prim_secded_69_61_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
62: begin
  secded_70_62_t data_dec_t;
  assign encode_ecc_data = prim_secded_70_62_enc(raw_encode_data);
  assign data_dec_t = prim_secded_70_62_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
63: begin
  secded_71_63_t data_dec_t;
  assign encode_ecc_data = prim_secded_71_63_enc(raw_encode_data);
  assign data_dec_t = prim_secded_71_63_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
64: begin
  secded_72_64_t data_dec_t;
  assign encode_ecc_data = prim_secded_72_64_enc(raw_encode_data);
  assign data_dec_t = prim_secded_72_64_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
65: begin
  secded_73_65_t data_dec_t;
  assign encode_ecc_data = prim_secded_73_65_enc(raw_encode_data);
  assign data_dec_t = prim_secded_73_65_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
66: begin
  secded_74_66_t data_dec_t;
  assign encode_ecc_data = prim_secded_74_66_enc(raw_encode_data);
  assign data_dec_t = prim_secded_74_66_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
67: begin
  secded_75_67_t data_dec_t;
  assign encode_ecc_data = prim_secded_75_67_enc(raw_encode_data);
  assign data_dec_t = prim_secded_75_67_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
68: begin
  secded_76_68_t data_dec_t;
  assign encode_ecc_data = prim_secded_76_68_enc(raw_encode_data);
  assign data_dec_t = prim_secded_76_68_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
69: begin
  secded_77_69_t data_dec_t;
  assign encode_ecc_data = prim_secded_77_69_enc(raw_encode_data);
  assign data_dec_t = prim_secded_77_69_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
70: begin
  secded_78_70_t data_dec_t;
  assign encode_ecc_data = prim_secded_78_70_enc(raw_encode_data);
  assign data_dec_t = prim_secded_78_70_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
71: begin
  secded_79_71_t data_dec_t;
  assign encode_ecc_data = prim_secded_79_71_enc(raw_encode_data);
  assign data_dec_t = prim_secded_79_71_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
72: begin
  secded_80_72_t data_dec_t;
  assign encode_ecc_data = prim_secded_80_72_enc(raw_encode_data);
  assign data_dec_t = prim_secded_80_72_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
73: begin
  secded_81_73_t data_dec_t;
  assign encode_ecc_data = prim_secded_81_73_enc(raw_encode_data);
  assign data_dec_t = prim_secded_81_73_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
74: begin
  secded_82_74_t data_dec_t;
  assign encode_ecc_data = prim_secded_82_74_enc(raw_encode_data);
  assign data_dec_t = prim_secded_82_74_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
75: begin
  secded_83_75_t data_dec_t;
  assign encode_ecc_data = prim_secded_83_75_enc(raw_encode_data);
  assign data_dec_t = prim_secded_83_75_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
76: begin
  secded_84_76_t data_dec_t;
  assign encode_ecc_data = prim_secded_84_76_enc(raw_encode_data);
  assign data_dec_t = prim_secded_84_76_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
77: begin
  secded_85_77_t data_dec_t;
  assign encode_ecc_data = prim_secded_85_77_enc(raw_encode_data);
  assign data_dec_t = prim_secded_85_77_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
78: begin
  secded_86_78_t data_dec_t;
  assign encode_ecc_data = prim_secded_86_78_enc(raw_encode_data);
  assign data_dec_t = prim_secded_86_78_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
79: begin
  secded_87_79_t data_dec_t;
  assign encode_ecc_data = prim_secded_87_79_enc(raw_encode_data);
  assign data_dec_t = prim_secded_87_79_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
80: begin
  secded_88_80_t data_dec_t;
  assign encode_ecc_data = prim_secded_88_80_enc(raw_encode_data);
  assign data_dec_t = prim_secded_88_80_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
81: begin
  secded_89_81_t data_dec_t;
  assign encode_ecc_data = prim_secded_89_81_enc(raw_encode_data);
  assign data_dec_t = prim_secded_89_81_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
82: begin
  secded_90_82_t data_dec_t;
  assign encode_ecc_data = prim_secded_90_82_enc(raw_encode_data);
  assign data_dec_t = prim_secded_90_82_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
83: begin
  secded_91_83_t data_dec_t;
  assign encode_ecc_data = prim_secded_91_83_enc(raw_encode_data);
  assign data_dec_t = prim_secded_91_83_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
84: begin
  secded_92_84_t data_dec_t;
  assign encode_ecc_data = prim_secded_92_84_enc(raw_encode_data);
  assign data_dec_t = prim_secded_92_84_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
85: begin
  secded_93_85_t data_dec_t;
  assign encode_ecc_data = prim_secded_93_85_enc(raw_encode_data);
  assign data_dec_t = prim_secded_93_85_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
86: begin
  secded_94_86_t data_dec_t;
  assign encode_ecc_data = prim_secded_94_86_enc(raw_encode_data);
  assign data_dec_t = prim_secded_94_86_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
87: begin
  secded_95_87_t data_dec_t;
  assign encode_ecc_data = prim_secded_95_87_enc(raw_encode_data);
  assign data_dec_t = prim_secded_95_87_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
88: begin
  secded_96_88_t data_dec_t;
  assign encode_ecc_data = prim_secded_96_88_enc(raw_encode_data);
  assign data_dec_t = prim_secded_96_88_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
89: begin
  secded_97_89_t data_dec_t;
  assign encode_ecc_data = prim_secded_97_89_enc(raw_encode_data);
  assign data_dec_t = prim_secded_97_89_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
90: begin
  secded_98_90_t data_dec_t;
  assign encode_ecc_data = prim_secded_98_90_enc(raw_encode_data);
  assign data_dec_t = prim_secded_98_90_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
91: begin
  secded_99_91_t data_dec_t;
  assign encode_ecc_data = prim_secded_99_91_enc(raw_encode_data);
  assign data_dec_t = prim_secded_99_91_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
92: begin
  secded_100_92_t data_dec_t;
  assign encode_ecc_data = prim_secded_100_92_enc(raw_encode_data);
  assign data_dec_t = prim_secded_100_92_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
93: begin
  secded_101_93_t data_dec_t;
  assign encode_ecc_data = prim_secded_101_93_enc(raw_encode_data);
  assign data_dec_t = prim_secded_101_93_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
94: begin
  secded_102_94_t data_dec_t;
  assign encode_ecc_data = prim_secded_102_94_enc(raw_encode_data);
  assign data_dec_t = prim_secded_102_94_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
95: begin
  secded_103_95_t data_dec_t;
  assign encode_ecc_data = prim_secded_103_95_enc(raw_encode_data);
  assign data_dec_t = prim_secded_103_95_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
96: begin
  secded_104_96_t data_dec_t;
  assign encode_ecc_data = prim_secded_104_96_enc(raw_encode_data);
  assign data_dec_t = prim_secded_104_96_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
97: begin
  secded_105_97_t data_dec_t;
  assign encode_ecc_data = prim_secded_105_97_enc(raw_encode_data);
  assign data_dec_t = prim_secded_105_97_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
98: begin
  secded_106_98_t data_dec_t;
  assign encode_ecc_data = prim_secded_106_98_enc(raw_encode_data);
  assign data_dec_t = prim_secded_106_98_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
99: begin
  secded_107_99_t data_dec_t;
  assign encode_ecc_data = prim_secded_107_99_enc(raw_encode_data);
  assign data_dec_t = prim_secded_107_99_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
100: begin
  secded_108_100_t data_dec_t;
  assign encode_ecc_data = prim_secded_108_100_enc(raw_encode_data);
  assign data_dec_t = prim_secded_108_100_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
101: begin
  secded_109_101_t data_dec_t;
  assign encode_ecc_data = prim_secded_109_101_enc(raw_encode_data);
  assign data_dec_t = prim_secded_109_101_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
102: begin
  secded_110_102_t data_dec_t;
  assign encode_ecc_data = prim_secded_110_102_enc(raw_encode_data);
  assign data_dec_t = prim_secded_110_102_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
103: begin
  secded_111_103_t data_dec_t;
  assign encode_ecc_data = prim_secded_111_103_enc(raw_encode_data);
  assign data_dec_t = prim_secded_111_103_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
104: begin
  secded_112_104_t data_dec_t;
  assign encode_ecc_data = prim_secded_112_104_enc(raw_encode_data);
  assign data_dec_t = prim_secded_112_104_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
105: begin
  secded_113_105_t data_dec_t;
  assign encode_ecc_data = prim_secded_113_105_enc(raw_encode_data);
  assign data_dec_t = prim_secded_113_105_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
106: begin
  secded_114_106_t data_dec_t;
  assign encode_ecc_data = prim_secded_114_106_enc(raw_encode_data);
  assign data_dec_t = prim_secded_114_106_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
107: begin
  secded_115_107_t data_dec_t;
  assign encode_ecc_data = prim_secded_115_107_enc(raw_encode_data);
  assign data_dec_t = prim_secded_115_107_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
108: begin
  secded_116_108_t data_dec_t;
  assign encode_ecc_data = prim_secded_116_108_enc(raw_encode_data);
  assign data_dec_t = prim_secded_116_108_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
109: begin
  secded_117_109_t data_dec_t;
  assign encode_ecc_data = prim_secded_117_109_enc(raw_encode_data);
  assign data_dec_t = prim_secded_117_109_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
110: begin
  secded_118_110_t data_dec_t;
  assign encode_ecc_data = prim_secded_118_110_enc(raw_encode_data);
  assign data_dec_t = prim_secded_118_110_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
111: begin
  secded_119_111_t data_dec_t;
  assign encode_ecc_data = prim_secded_119_111_enc(raw_encode_data);
  assign data_dec_t = prim_secded_119_111_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
112: begin
  secded_120_112_t data_dec_t;
  assign encode_ecc_data = prim_secded_120_112_enc(raw_encode_data);
  assign data_dec_t = prim_secded_120_112_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
113: begin
  secded_121_113_t data_dec_t;
  assign encode_ecc_data = prim_secded_121_113_enc(raw_encode_data);
  assign data_dec_t = prim_secded_121_113_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
114: begin
  secded_122_114_t data_dec_t;
  assign encode_ecc_data = prim_secded_122_114_enc(raw_encode_data);
  assign data_dec_t = prim_secded_122_114_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
115: begin
  secded_123_115_t data_dec_t;
  assign encode_ecc_data = prim_secded_123_115_enc(raw_encode_data);
  assign data_dec_t = prim_secded_123_115_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
116: begin
  secded_124_116_t data_dec_t;
  assign encode_ecc_data = prim_secded_124_116_enc(raw_encode_data);
  assign data_dec_t = prim_secded_124_116_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
117: begin
  secded_125_117_t data_dec_t;
  assign encode_ecc_data = prim_secded_125_117_enc(raw_encode_data);
  assign data_dec_t = prim_secded_125_117_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
118: begin
  secded_126_118_t data_dec_t;
  assign encode_ecc_data = prim_secded_126_118_enc(raw_encode_data);
  assign data_dec_t = prim_secded_126_118_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
119: begin
  secded_127_119_t data_dec_t;
  assign encode_ecc_data = prim_secded_127_119_enc(raw_encode_data);
  assign data_dec_t = prim_secded_127_119_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
120: begin
  secded_128_120_t data_dec_t;
  assign encode_ecc_data = prim_secded_128_120_enc(raw_encode_data);
  assign data_dec_t = prim_secded_128_120_dec(ecc_decode_data);
  assign decode_raw_data = data_dec_t.data;
  assign ecc_single_err = data_dec_t.err[0];
  assign ecc_double_err = data_dec_t.err[1];
end
default: begin : g_unsupported_width
  assign encode_ecc_data = '0;
  assign decode_raw_data = '0;
  assign ecc_single_err = 1'b0;
  assign ecc_double_err = 1'b0;
end
endcase

`ifndef SYNTHESIS
initial begin
  assert (RAW_DATA_WIDTH inside {[2:120]})
    else $fatal(1, "ecc_codec RAW_DATA_WIDTH is unsupported");
  assert (ECC_DATA_WIDTH == RAW_DATA_WIDTH +
          get_parity_width(RAW_DATA_WIDTH) + 1)
    else $fatal(1, "ecc_codec ECC_DATA_WIDTH does not match RAW_DATA_WIDTH");
end
`endif

endmodule

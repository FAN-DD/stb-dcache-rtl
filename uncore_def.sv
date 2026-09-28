`ifndef UNCORE_DEF_SV
`define UNCORE_DEF_SV
`define NUM_FAST_IRQ 256
`define HAS_ICDC_AHB
`define HAS_Periph_AHB
`define W_AXDATA 64
`define W_AXID 5
`define W_AXLEN 8
`define W_AXSIZE 4
`define HAS_PREDECODE

`define HAS_ITIM
`define ITIM_16M
`define HAS_ITIM_ECC
`ifdef HAS_ITIM_ECC
  `ifndef HAS_Mem_Check
    `define HAS_Mem_Check
  `endif
  `ifndef HAS_ECC_NMI
    `define HAS_ECC_NMI
  `endif
`endif
`ifdef HAS_ITIM
`define ITIM_B 32'h1C00_0000
`define ITIM_MEM_DATA_WIDTH 64

`ifdef ITIM_16K
  `define ITIM_E `ITIM_B + 32'h3FFF
  `define ITIM_MEM_ADDR_WIDTH 11
`elsif ITIM_32K
  `define ITIM_E `ITIM_B + 32'h7FFF
  `define ITIM_MEM_ADDR_WIDTH 12
`elsif ITIM_64K
  `define ITIM_E `ITIM_B + 32'hFFFF
  `define ITIM_MEM_ADDR_WIDTH 13
`elsif ITIM_128K
  `define ITIM_E `ITIM_B + 32'h1_FFFF
  `define ITIM_MEM_ADDR_WIDTH 14
`elsif ITIM_16M
  `define ITIM_E `ITIM_B + 32'hFF_FFFF
  `define ITIM_MEM_ADDR_WIDTH 21
`endif
`endif

`define HAS_DTIM
`define DTIM_16M
`define HAS_DTIM_ECC
`ifdef HAS_DTIM_ECC
  `ifndef HAS_Mem_Check
    `define HAS_Mem_Check
  `endif
  `ifndef HAS_ECC_NMI
    `define HAS_ECC_NMI
  `endif
`endif
`ifdef HAS_DTIM
`define DTIM_B 32'h1E00_0000
`define DTIM_MEM_DATA_WIDTH 64
`define DTIM_MEM_DATA_WIDTH_W 32

`ifdef DTIM_16K
  `define DTIM_E `DTIM_B + 32'h3FFF
  `define DTIM_MEM_ADDR_WIDTH 11
`elsif DTIM_32K
  `define DTIM_E `DTIM_B + 32'h7FFF
  `define DTIM_MEM_ADDR_WIDTH 12
`elsif DTIM_64K
  `define DTIM_E `DTIM_B + 32'hFFFF
  `define DTIM_MEM_ADDR_WIDTH 13
`elsif DTIM_128K
  `define DTIM_E `DTIM_B + 32'h1_FFFF
  `define DTIM_MEM_ADDR_WIDTH 14
`elsif DTIM_16M
  `define DTIM_E `DTIM_B + 32'hFF_FFFF
  `define DTIM_MEM_ADDR_WIDTH 21
`endif
`endif

`define HAS_ICache
`ifdef HAS_ICache
  `ifndef HAS_BUS_NMI
    `define HAS_BUS_NMI
    `define HAS_Mem_Check
  `endif
  `ifndef HAS_Mem_Check
    `define HAS_Mem_Check
  `endif
`endif
`define ICache_128M

`define HAS_ICache_Parity
`ifdef HAS_ICache_ECC
  `ifndef HAS_Mem_Check
    `define HAS_Mem_Check
  `endif
  `ifndef HAS_ECC_NMI
    `define HAS_ECC_NMI
  `endif
  `ifndef HAS_ICache_Check
    `define HAS_ICache_Check
  `endif
`endif

`ifdef HAS_ICache_Parity
  `ifndef HAS_Mem_Check
    `define HAS_Mem_Check
  `endif
  `ifndef HAS_PARITY_NMI
    `define HAS_PARITY_NMI
  `endif
  `ifndef HAS_ICache_Check
    `define HAS_ICache_Check
  `endif
`endif

`ifdef HAS_ICache
`define ICache_B 32'h1000_0000

`ifdef ICache_256K
  `define ICache_E `ICache_B + 32'h3_FFFF
  `define ICAddrW 18
`elsif ICache_1M
  `define ICache_E `ICache_B + 32'hF_FFFF
  `define ICAddrW 20
`elsif ICache_128M
  `define ICache_E `ICache_B + 32'h7FF_FFFF
  `define ICAddrW 27
`elsif ICache_1G
  `define ICache_E `ICache_B + 32'h3FFF_FFFF
  `define ICAddrW 30
`endif
`endif

`define HAS_DCache
`ifndef HAS_DCache
  `define HAS_Sys
  `define Sys_256K
`endif
`ifdef HAS_DCache
  `ifndef HAS_CBO_NMI
    `define HAS_CBO_NMI
  `endif
  `ifndef HAS_Mem_Check
    `define HAS_Mem_Check
  `endif
`endif
`define DCache_128M
`define HAS_DCache_ECC
`ifdef HAS_DCache_ECC
  `ifndef HAS_Mem_Check
    `define HAS_Mem_Check
  `endif
  `ifndef HAS_ECC_NMI
    `define HAS_ECC_NMI
  `endif
  `ifndef HAS_DCache_Check
    `define HAS_DCache_Check
  `endif
`endif

`ifdef HAS_DCache_Parity
  `ifndef HAS_Mem_Check
    `define HAS_Mem_Check
  `endif
  `ifndef HAS_PARITY_NMI
    `define HAS_PARITY_NMI
  `endif
  `ifndef HAS_DCache_Check
    `define HAS_DCache_Check
  `endif
`endif
`define DCACHE_WAY_4

`ifdef HAS_DCache
  `define DCache_B 32'h1000_0000
  `ifdef DCache_256K
    `define DCache_E `DCache_B + 32'h3_FFFF
  `elsif DCache_1M
    `define DCache_E `DCache_B + 32'hF_FFFF
  `elsif DCache_128M
    `define DCache_E `DCache_B + 32'h7FF_FFFF
  `elsif DCache_1G
    `define DCache_E `DCache_B + 32'h3FFF_FFFF
  `endif
`else
  `ifdef HAS_Sys
    `define Sys_B 32'h6000_0000
    `define DCache_B `Sys_B 
    `ifdef Sys_256K
      `define Sys_E `Sys_B + 32'h4_0000
      `define SysAddrW 18
    `elsif Sys_128M
      `define Sys_E `Sys_B + 32'h800_0000
      `define SysAddrW 27
    `elsif Sys_1G
      `define Sys_E `Sys_B + 32'h4000_0000
      `define SysAddrW 32
    `endif
  `endif
`endif

`define HAS_Periph
`define PeriAddrW 32
`ifdef HAS_Periph
  `ifndef HAS_BUS_NMI
    `define HAS_BUS_NMI
  `endif
  `ifndef HAS_Mem_Check
    `define HAS_Mem_Check
  `endif
`endif
`define Periph_3G
`ifdef HAS_Periph
`define Periph_B 32'h4000_0000

`ifdef Periph_512M
  `define Periph_E `Periph_B + 32'h1FFF_FFFF
`elsif Periph_1G
  `define Periph_E `Periph_B + 32'h3FFF_FFFF
`elsif Periph_3G
  `define Periph_E `Periph_B + 32'hBFFF_FFFF
`endif
`endif

`ifdef HAS_Mem_Check
  `define HAS_CacheCtrl
  `define CacheCtrl_BASE_ADDR 32'h0000_0000
`endif

`ifdef HAS_CacheCtrl
  `define CacheCtrl_B (`CacheCtrl_BASE_ADDR + 32'h0000_2000)
  `define CacheCtrl_E (`CacheCtrl_BASE_ADDR + 32'h0000_2FFF)
`endif

`define CLIC_COMP_INSERT_FF 
`define IFU_BUF_CNT 0
`define Peri_BUF_CNT 1
`define DM_BUF_CNT 1

`define IFU_MASID  3'b000
`define DC_MASID   3'b001
`define FP_MASID   3'b010
`define DTIM_MASID 3'b011
`define DEV_MASID  3'b100

`define PutFullData    0 
`define PutPartialData 1 
`define ArithmeticData 2 
`define LogicalData    3 
`define Get            4 
`define Hint           5 
`define AcquireBlock   6 
`define AcquirePerm    7 
`define Probe          6 
`define AccessAck      0 
`define AccessAckData  1 
`define HintAck        2 
`define ProbeAck       4 
`define ProbeAckData   5 
`define Release        6 
`define ReleaseData    7 
`define Grant          4 
`define GrantData      5 
`define ReleaseAck     6 
`define GrantAck       0 

`define MasSizeW       3
`define MasIdWidth     1
`define NumMas         5 
`define SlvIdWidth     (`MasIdWidth + $clog2(`NumMas)) 
`define MasAddrWidth   32
`define MasDataWidth   64
`define MasDataWidth_w 32

`define CacheSrcIdW    (`SlvIdWidth + 1) 

`define TLAhbFastQSize 4
`endif

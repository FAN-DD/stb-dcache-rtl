`ifndef DCACHE_DEF_SV
`define DCACHE_DEF_SV
`include "uncore_def.sv"

`ifdef DCache_256K
  `define dcAddrWidth 18
  `define dcAddrMSB 14'(`DCache_B >> 18)
  `define dcAddrMSBWidth 14
`elsif DCache_1M
  `define dcAddrWidth 20
  `define dcAddrMSB 12'(`DCache_B >> 20)
  `define dcAddrMSBWidth 12
`elsif DCache_128M
  `define dcAddrWidth 27
  `define dcAddrMSB 5'(`DCache_B >> 27)
  `define dcAddrMSBWidth 5
`endif

`ifndef dCacheSize
`define dCacheSize 128
`endif

`define dCachelineSize32

`ifdef dCachelineSize32
  `define dCachelineSize 32
`endif

`ifdef dCachelineSize16
  `define dCachelineSize 16
`endif

`ifdef dCachelineSize8
  `define dCachelineSize 8
`endif

`ifdef DCACHE_WAY_4
  `define dcTagEntry (`dCacheSize * 1024 / `dCachelineSize / 4)
  `define dcDataEntry (`dCacheSize * 1024 / 8 / 4)
  `define dcTagRamRawWidth (4 * `dcTagWidth + 4)
  `define dcValidBits (`dcTagEntry * 4)
`endif

`define dcTagIdxWidth $clog2(`dcTagEntry)
`define dcDataIdxWidth $clog2(`dcDataEntry)

`define dcTagWidth (`dcAddrWidth -3 - `dcDataIdxWidth)

`define VcEntry 1
`define EntryWidth $clog2(`VcEntry+1)
`define VcAddrWidth (`dcTagWidth + `dcTagIdxWidth)

`define MaxBeat (`dCachelineSize / 8)
`define dcLastBeat (`MaxBeat -1)
`define dclineOffset $clog2(`dCachelineSize)

`ifdef HAS_DCache_Parity
  `define dcParityWidth 1
`else
  `define dcParityWidth 0
`endif

`ifdef HAS_DCache_ECC
  `define dcTagEccWidth (4 + (`dcTagRamRawWidth>4)+ (`dcTagRamRawWidth>11) + (`dcTagRamRawWidth>26) + (`dcTagRamRawWidth>57)+ (`dcTagRamRawWidth>120))
  `define dcDataEccWidth 8
`else
  `define dcTagEccWidth 0
  `define dcDataEccWidth 0
`endif

`define dcTagRamWidth (`dcParityWidth + `dcTagEccWidth + `dcTagRamRawWidth)
`define dcDataRamWidth (`dcParityWidth + `dcDataEccWidth + `MasDataWidth)

`ifdef HAS_DCache_Check
  `define dcDataWmWidth 9
`else
`define dcDataWmWidth 8
`endif
`endif

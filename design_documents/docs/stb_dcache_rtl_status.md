# stb_dcache 首版RTL实现与验证状态

更新日期：2026-09-24。

首版RTL已按LLD实现，顶层`stb_dcache.sv`保持原61个端口不变，仅增加可选参数`STB_DEPTH=4`。逻辑分为STB/LSU前端、DCache主控制和BIU多拍引擎；这三个文件是内部实现划分，不增加顶层接口。

| 文件 | 作用 |
| --- | --- |
| `stb_dcache.sv` | 原顶层接口、四路SRAM接口展开和内部模块连接 |
| `stb_dc_front.sv` | 4项默认STB、任意entry同址合并、两级Store转发源、LSU接收/响应顺序、LR/SC reservation |
| `stb_dc_core.sv` | blocking DCache主FSM、Tag/Data ECC、替换/refill/writeback、AMO/LR/SC和CBO |
| `stb_dc_biu.sv` | 单outstanding Get/Put多拍握手、反压保持、首A后D响应和错误累计 |
| `stb_dc_pkg.sv` | 内部请求类型、字节合并、AMO运算和16bit LFSR函数 |
| `rtl.f` | Questa编译顺序 |
| `sim/tb_stb_dcache.sv` | 同步单端口SRAM、BIU模型、记分板、断言和定向/随机测试 |
| `sim/run.ps1` | Cache容量及STB深度参数化编译和回归入口 |
| `sim/check_rtl_gate.ps1` | 强制RTL门禁：风格、四容量lint、四组定向回归和混合随机 |

同时补齐了`uncore_pkg.sv`、`kratos_pkg.sv`的package包装和宏文件include guard；修正了现有`ecc_codec.sv`访问`prim_secded_pkg`解码结构体时使用的字段名，使ECC适配能够展开和仿真。

## 已完成检查

- `powershell -File sim/check_rtl_gate.ps1`完整门禁：PASS。
- Questa 2024.1四种容量`vlog -sv -lint`：均为0 error，0 warning。
- 顶层端口声明仍为61项，端口名和方向未增删。
- 四种Cache容量均重新编译并运行同一组测试；STB深度覆盖1、2、3、4，包含非2次幂深度3。

| Cache / STB | 结果 | LSU响应数 | Get / Put |
| --- | --- | ---: | ---: |
| 16KiB / 1 | PASS | 426 | 262 / 153 |
| 32KiB / 2 | PASS | 428 | 262 / 152 |
| 64KiB / 3 | PASS | 431 | 271 / 157 |
| 128KiB / 4 | PASS | 433 | 270 / 154 |

主要覆盖：STB满/合并/反压、drain同拍Store合并、STB与pending联合转发、部分转发等待；Load hit T3同沿接下一DC请求；clean/dirty miss、回写和逐beat安装；四种critical beat、Get首A后下一拍首D、A/D随机反压、Put早应答；关键beat前/本拍/后bus error；全部AMO运算和两个lane、AMO hit/miss拆拍；LR/SC hit/miss/失败/外部失效/CBO失效；六种CBO及保持请求去重；Tag/Data单错修复、双错继续与CBO sticky错误；writeback错误和随机有序Load/Store。

## 尚未完成

当前结果证明的是RTL编译、定向/随机功能仿真和参数展开，不等同于项目签核。尚需接入项目级LSU/BIU环境，运行覆盖率与协议断言回归，并使用项目批准的TSMC 22ULL标准单元和SRAM库完成综合、形式/CDC检查、布局布线及1GHz sign-off STA。真实SRAM的写mask、CEB/WEB极性和读时序也需在宏模型联调时再次核对。

运行强制RTL门禁：

```powershell
powershell -NoProfile -File sim/check_rtl_gate.ps1
```

编辑过程可使用`-LintOnly`快速检查，但不能代替提交前的默认完整门禁。

## 混合随机波形

已在 128KiB Cache、4 项 STB 配置下，以固定种子 `0x5a17c0de` 完成 300 次加权随机选择。测试包含固定覆盖前导序列，因此 Load、全写 Store、部分写 Store、全部算术/逻辑 AMO、LR/SC 成功与失败，以及六种 CBO 均至少执行一次；所有请求均纳入参考模型检查。

本次结果为 PASS，共收到 846 个 LSU 响应，BIU 发出 340 个 Get 和 189 个 Put。分类计数如下：

- Load 575；全写 Store 46；部分写 Store 38。
- 算术 AMO 27；逻辑 AMO 47；LR/SC 成功 34；LR/SC 失败 15。
- CBO INVAL/CLEAN/FLUSH/ZERO/CLEAN_ALL/INVAL_ALL 分别为 7/10/10/5/13/7。

运行和查看命令：

```powershell
powershell -NoProfile -File sim/run_random.ps1 -Ops 300 -Seed 1511506142 -CacheKiB 128 -StbDepth 4
vsim -view sim/results/mixed_random_cache128_stb4_seed1511506142.wlf -do sim/wave_random_view.do
```

波形中的 `mix_op_kind` 标识当前随机操作类型：1=Load，2=全写 Store，3=部分写 Store，4=算术 AMO，5=逻辑 AMO，6=LR/SC 成功场景，7=LR/SC 失败场景，8~13 依次对应六种 CBO。

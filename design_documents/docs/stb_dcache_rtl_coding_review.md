# stb_dcache RTL编码规范审查

日期：2026-09-24。审查基线为项目内 [rtl-rule Skill](../skills/rtl-rule/SKILL.md)：SystemVerilog IEEE 1800-2017、TSMC 22ULL、sign-off 1GHz（1.000ns），并保持当前LLD规定的T1/T2/T3及AMO T4边界。

## 审查结论

已审查全部设计RTL：`rtl.f`列出的10个编译单元，以及被其包含的`dcache_def.sv`、`uncore_def.sv`；`sim/tb_stb_dcache.sv`属于验证代码，不计入设计RTL合规结论。项目自有RTL现已满足rtl-rule Skill强制门禁：综合语义、复位、时序过程、CDC、SRAM控制、命名常量、显式位宽及可读性检查均通过。格式豁免仅限[受控豁免清单](rtl_style_waivers.md)中的生成代码和既有系统宏接口，这些文件仍参加所有编译和lint。当前未发现新的确定性功能错误；完整门禁、四种参数回归和混合随机全部通过。没有项目批准的TSMC 22ULL标准单元、SRAM库、PVT/RC及variation约束，因此不能宣称已通过1GHz sign-off。

本项目所称1GHz sign-off要求是布局布线后、带提取寄生参数的多模式多角STA验收，包括setup/hold、recovery/removal、最小脉宽、clock-gating、最大transition/capacitance/fanout、未约束路径及全部时序例外审计；具体角和数值标准以项目签核流程为准。

## 审查范围与合规状态

| 文件或类别 | 结论 | 说明 |
| --- | --- | --- |
| `stb_dc_biu.sv` | 满足 | 握手、payload保持、计数推进、命名常量、显式位宽和过程类型通过 |
| `stb_dc_front.sv` | 满足 | STB合并、转发、响应、复位、TileLink参数常量和格式检查通过 |
| `stb_dc_core.sv` | 满足 | 主FSM、ECC、refill、CBO、单端口SRAM互斥、显式控制常量和格式检查通过 |
| `stb_dcache.sv` | 满足 | 顶层连接、条件编译、实例化及连续赋值格式检查通过 |
| `stb_dc_pkg.sv` | 满足 | 合并、AMO、lane和LFSR函数通过；AMO及TileLink参数已使用命名常量 |
| `ecc_pkg.sv`、`kratos_pkg.sv`、`uncore_pkg.sv` | 满足 | 函数、枚举、接口结构和格式检查通过 |
| `ecc/ecc_codec.sv` | 满足 | 当前使用宽度正确展开；已增加unsupported-width默认分支及raw/code宽度一致性检查 |
| `dcache_def.sv`、`uncore_def.sv` | 受控格式豁免 | 既有系统宏接口；仍参加四种容量编译和lint，豁免边界见`rtl_style_waivers.md` |
| `ecc/prim_secded_pkg.sv` | 生成代码例外 | 文件头明确由lowRISC SECDED生成器产生；核对了本设计使用的编码/解码函数及raw/ECC位布局，不手工重排生成文件 |

因此，所有设计RTL均已review，所有项目自有RTL均通过Skill强制门禁；生成代码和既有系统宏仅按已记录范围豁免格式检查，不豁免编译、lint和功能回归。

## 已修正

| 项目 | 原问题 | 修正 |
| --- | --- | --- |
| STB合并索引 | `merge_index`使用32bit `int`，实际只需要STB指针宽度 | 改为 `logic [PW-1:0]`，循环索引显式转换为 `PW'(n)` |
| 过程类型 | 四处仿真断言监控使用普通 `always @(posedge clk_i)` | 改为 `always_ff @(posedge clk_i)`；仍受 `ifndef SYNTHESIS` 保护 |
| TileLink opcode | Front和BIU散落使用数字 `0/1/2/3/4` | 改用已有的 `PutFullData`、`PutPartialData`、`Get`、`AccessAck`、`AccessAckData` 等协议宏 |
| BIU line size | 32B事务size直接写 `3'd5` | 增加命名常量 `LINE_SIZE` |
| 协议及控制常量 | AMO param、TileLink param/size、beat、scan phase及ECC类型仍有散落数字 | 统一为命名且显式定宽的`localparam` |
| 可读性 | 主RTL存在大量一行多语句和紧凑运算符写法 | 拆分声明、默认值、状态动作、寄存器更新和模块实例化，保持原有同拍覆盖优先级 |
| ECC参数防护 | `ecc_codec`不支持的宽度会留下未驱动输出 | 增加默认分支、raw宽度范围及code宽度一致性断言 |
| 强制门禁 | 原先依赖人工执行lint和回归 | 新增`sim/check_rtl_gate.ps1`，默认执行风格检查、四容量lint、四组定向回归及混合随机 |

这些修改不增加寄存级、不改变端口、状态转移或请求延迟。

## 符合项

- 可综合时序逻辑使用 `always_ff`，组合逻辑使用 `always_comb`；未发现意外latch的lint报告。
- 时序状态使用非阻塞赋值，组合计算使用阻塞赋值。
- 功能状态使用低有效异步复位；参数检查和断言 `initial` 均位于 `ifndef SYNTHESIS` 内。
- 当前模块只有 `clk_i` 一个功能时钟，没有实际CDC路径。
- 结构体和数组使用 `wire` 的位置均为模块输入边界，属于允许的net语义例外；内部状态使用 `logic`。
- AMO hit已拆分到T4写入，避免将Tag命中、AMO ALU、ECC编码和SRAM写全部压在普通Store的T3边界内。
- SRAM为同步单端口使用方式；当前控制未在同一宏采样沿同时安排读写。
- `test_mode_i`当前仅预留。没有在缺少目标TSMC 22ULL ICG单元、DFT test-enable和门控检查约束时自行构造门控时钟，这是合理选择。

## 仍需关注的1GHz路径

以下是结构审查结果，不是STA结论：

1. **Load接收与STB转发路径**：四个entry的地址比较、逐字节优先合并、`full_forward`判断及 `tl_slv_a_rdy_o` 形成同周期组合路径。STB深度固定4时规模有限，但应列为前端关键路径。
2. **普通Store hit T2→T3**：已寄存Tag/Data经过四路Tag比较、way选择、64bit字节合并、SECDED编码后驱动Data SRAM写口。该路径实现既定三拍延迟，也最需要真实TSMC 22ULL库和SRAM setup约束验证。
3. **普通Load hit返回**：命中way选择、DCache数据选择、Front保存字节覆盖和D通道输出位于同一周期；Load hit同沿turnover还增加完成判断到下一请求ready及SRAM读控制的路径。
4. **Refill输入路径**：BIU D数据经过目标beat判断、Store字节覆盖和SECDED编码进入写命令寄存器。其输入延迟和时钟不确定性必须进入STA。
5. **Valid阵列扇出**：128KiB配置有1024 set × 4bit Valid寄存器。异步复位以及 `CBO_INVAL_ALL` 单沿清零会形成较大的复位/清零扇出，应由综合和物理实现检查面积、布线与恢复时间。
6. **单体Core组合控制**：`stb_dc_core` 的主 `always_comb` 较大。综合只保留实际依赖锥，但需要通过时序报告确认状态译码、错误处理和SRAM控制没有形成意外长路径。

## 第二轮功能结构审查

- **Tag码字镜像**：AMO/refill/zero提交Tag时，RTL使用 `install_tag[RW-1:0]` 更新内部raw Tag镜像。已核对当前 `prim_secded_*_enc` 实现：原始数据位固定放在码字低位，ECC位追加在高位，因此该切片与四种Tag宽度均一致。
- **BIU背压保持**：A通道计数只在 `a_valid && a_ready` 时推进；base、Put/Get类型和line buffer在事务期间保持。D通道只在允许接收refill beat或Put应答时拉高ready，没有发现payload随stall变化的问题。
- **首A/首D间隔**：`d_ready_o`只在首个A握手已寄存后拉高；首D最早下一拍握手，禁止首A/首D同拍，并去除A ready到D ready的组合路径。
- **Front/Core握手**：STB head在入队后的下一周期呈现；只有 `req_valid && req_ready` 的采样沿才释放entry。Core随后用pending请求保存完整payload，未发现Store数据在SRAM完成前丢失的路径。
- **单端口SRAM**：普通hit写、AMO写、scrub、victim读、refill写和CBO操作由主状态互斥控制；Load hit turnover只在没有修复和写占用时开放，没有发现同一way同沿读写命令冲突。
- **Tag/Data ECC错误**：单错使用纠正值并按既定规则修复；双错上报后继续当前访问。refill关键beat及此前错误决定LSU结果，晚到错误只阻止该行发布Valid，与当前LLD一致。
- **CDC**：所有功能状态和接口控制均使用 `clk_i`，当前没有需要同步器的跨时钟信号。

本轮没有发现需要再次修改RTL的确定性功能问题。剩余风险集中在目标工艺时序、Valid阵列物理实现以及尚未开展的形式/CDC/RDC/门级签核。

## 维护性与门禁

项目自有RTL已消除一行多语句、直接协议魔数、无防护参数展开和主要紧凑格式问题。完整门禁命令为`powershell -File sim/check_rtl_gate.ps1`；`-LintOnly`只允许用于编辑过程中的快速检查。格式豁免文件和理由记录在[rtl_style_waivers.md](rtl_style_waivers.md)，新增豁免必须先评审。

## 验证结果

| 配置 | 结果 | LSU响应 | Get / Put |
| --- | --- | ---: | ---: |
| 16KiB / STB 1 | PASS | 426 | 262 / 153 |
| 32KiB / STB 2 | PASS | 428 | 262 / 152 |
| 64KiB / STB 3 | PASS | 431 | 271 / 157 |
| 128KiB / STB 4 | PASS | 433 | 270 / 154 |

2026-09-24执行完整门禁：风格检查PASS；四种容量Questa `vlog -sv -lint`均为0 error、0 warning；四组参数化定向回归通过。混合随机覆盖Load、Full/Partial Store、全部Arithmetic/Logical AMO、LR/SC成功与失败及六种CBO，`seed=32'h5a17c0de`、300个选择、846个LSU响应，结果PASS。

## 签核缺口

- TSMC 22ULL目标库下的逻辑综合、面积/功耗报告。
- 真实Tag/Data SRAM宏的读写时序、mask和CEB/WEB检查。
- 1.000ns主时钟约束下，覆盖项目规定PVT/RC corners及variation方法的布局布线后setup/hold sign-off STA。
- 项目级CDC/RDC、形式检查、覆盖率收敛和门级仿真。

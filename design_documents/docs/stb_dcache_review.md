# stb_dcache v1.0 评审记录与 LLD 入口

状态：关键外部行为已收敛，首版RTL已按[LLD v1.0](stb_dcache_lld.md)实现并通过参数化定向仿真；总体组织见[微架构设计](stb_dcache_architecture.md)，实现结果见[RTL实现与验证状态](stb_dcache_rtl_status.md)。

2026-09-23进一步明确：目标工艺为TSMC 22ULL，`clk_i`必须sign-off达到1GHz，周期1.000ns。已同步到架构和LLD，尚未使用目标库完成综合、布局布线或sign-off STA。

## 六项评审结果

| 编号 | 本稿具体方案 | 主要影响 | 章节 |
| --- | --- | --- | --- |
| R1 | 4项等待队列+1项DC pending；任意有效entry同址合并，mask按位或；同址输入Store与drain同拍均接受则合并下发并释放entry，不重复入队；删除drain_hold | 满且不能合并ready=0；等待STB字节优先转发；内部候选只在实际接收沿采样 | 3–5；LLD 4 |
| R2 | 一个待完成Load；转发全命中下一拍返回，未命中/部分命中当拍直通DC；部分命中保存转发结果并停止新drain至D接收 | Load完成前不接后续A，但d_fire沿可同拍接受下一请求；无响应FIFO，D ready恒1 | 5–6；LLD 4、6 |
| R3 | T1请求握手与SRAM读同沿，T2 ECC结果寄存，T3普通Load返回/Store写；AMO多拆一拍，T3返回并寄存运算结果、T4写入 | AMO hit缩短组合写路径；普通Store T2→T3及T1输入路径仍须按1GHz核验 | 7；LLD 6、9 |
| R4 | Load/AMO关键beat及此前error返回0；之后beat错误只失效原行，不改响应、不撤回/补发D，含后续error与D握手同沿；LR失败0、SC失败1 | 用户已确认关键beat握手为错误分界；tl_d_error恒0，旧owner收尾不影响较新前台 | 13；LLD 1、6.3 |
| R5 | LR/AMO旧目标lane返回且另一半补零；AMO hit用10F/1F0，miss目标beat以1FF直接安装修改后完整双字 | 用户已确认miss合并安装，原另一半来自refill；无需再半字写，ECC按完整新双字计算 | 6、10；LLD 7 |
| R6 | 已确认：CBO req保持至ack，只执行一次；命令内bus error/双错分别累计，与ack同拍输出 | 单错不置CBO双错标志；常规ECC事件在检测阶段上报；CLEAN_ALL遇bus error后继续 | 11–12；LLD 8 |

## 同轮审阅的集成约定

- 替换策略最终结论：固定使用一个全局16bit LFSR；先选编号最低的invalid way，四路全有效时用LFSR[1:0]选择victim。无其他编译选项。128KiB下Valid 4096bit加替换状态16bit，共4112bit。
- VC结论：不设独立Victim Cache；保留32B victim回写缓冲。最新refill路径绕过整行缓冲，逐beat安装。旧VcEntry宏不作为约束，RTL阶段清理无引用宏。
- Tag raw 布局：`{dirty3,tag3,...,dirty0,tag0}`；Data wm[8] 写 ECC 字节。
- BIU size=5；writeback四拍地址恒定；master source按现有宏固定为{DC_MASID,1'b0}=4'b0010；出错refill仍返回四拍，作为BIU集成约束验证。
- check_en_i 只屏蔽常规 ECC 事件；CBO 专用错误不屏蔽。
- LSU tl_slv_d_rdy_i固定为1，单级D输出，无响应FIFO；BIU按协议处理反压，内部drain未获选时不冻结head。Load/原子上下文跨等待保存请求及必要转发信息。
- 用户已确定普通Load优先于等待中的STB drain：空闲时选择Load，无强制轮转/Store等待提权；已经握手的DCache事务不被抢占。Store转发全命中Load可与drain并行；AMO在模块内等待排空，CBO由上层等待`stb_drained_out`后发送。详见架构5.3节。
- `stb_drained_out = (stb_count == 0) && !pending_store_valid`；末项移交不能提前报空。`dc_fsm_busy` 描述 DCache/BIU/CBO/修复活动。
- 当前仅 cacheable 地址窗口；上游保证地址路由正确。
- 先使用寄存器 enable，工艺 ICG 与 test_mode_i 在具备单元信息后接入。

用户已澄清SC数据状态与error常量、AMO返回/写入布局、CBO命令去重及错误输出；不再把这三项列为待回答问题。LLD已补充寄存器生命周期、主/子FSM、hit周期表、miss微操作组合及同拍规则。新增实现细节可直接在LLD中批注，不重复询问已确认需求。

## 编码入口检查

已确认refill修订，详见[修订记录](stb_dcache_refill_revision.md)及LLD 6.3：

- Load/AMO用addr[4:3]识别关键beat，接受后下一周期返回；普通beat边收边安装，末个实际Data写与Tag/Valid同沿发布。
- 普通refill不走独立安装状态或重新lookup；Store/SC在接收沿形成完整安装命令，AMO关键beat按额外一拍流程合入；BIU完成用事件，不插B_DONE空拍。
- 晚到error只使原行invalid；AMO miss用1FF整字安装、hit保留掩码写，两项均获用户确认。
- AMO关键beat再拆一拍：mst D握手保存old，下一周期返回/寄存AMO写命令，再下一沿写入；关键beat后反压mst D一周期，避免单端口Data写冲突。非关键beat仍下一沿写。
- 最后Data/Tag/Valid提交沿不接下一DC请求，因为新请求T1必须同沿读单端口SRAM；提交后下一周期恢复接收。
- 普通Load前台响应与DC owner收尾分离，response_issued防止重复D及旧错误污染新请求；AMO互斥保持至完整收尾。LR/SC继续提交后返回/建锁。
- 末写提交占用单端口SRAM，下一DC请求在随后周期接受；不使用提交沿Valid旁路。1GHz输入组合路径仍待实际STA。

本次STB补充约束已同步至LLD第4节、时序第6节及架构第4–5节：

1. 合并mask使用按位或；STB满且不能合并时tl_slv_a_rdy_o=0。
2. Load完全命中下一拍返回；未命中/部分命中当拍直通DC，仅DC能接收时LSU握手，不先接收再排队。
3. 部分命中接受时保存转发data/mask，停止新drain至Load D接收；Load完成前不接后续LSU请求，d_fire完成沿可同时接受下一请求。
4. 同址普通Store与drain同拍均被接受时直接合并下发，释放entry、不重复入队；取消drain_hold及队尾限定合并。
5. AMO/LR/SC等待队列与DC pending Store全部结束；最后一项出队不等于排空，等待期间允许旧Store继续drain。
6. 前台删除F_RESP，仅保留F_IDLE/F_WAIT；普通Load d_fire沿同时开放下一请求接收。旧上下文/D valid/stall清除后，同沿新上下文/新响应/新stall装载具有最终优先级；STB满且不能合并等原有反压条件继续有效。

原有接收后多拍Load查询/派发流程已替换为当拍查询和直通，相关寄存器、状态及验证要求同步更新。1GHz下的组合查找、ready和同拍合并下发路径列为后续STA检查项，当前未验证达标。

## 冗余周期检查（2026-09-22）

用户要求取消miss派发等待，并检查其他同类低效设计。本轮已更新LLD 5.1–5.3、6.4及配套架构图：

| 检查发现 | 当前实现基线 |
| --- | --- |
| LOOKUP_EVAL已知miss仍转MISS_SELECT | 删除独立选择状态，victim/Dirty与Tag比较并行；clean/invalid在T3可完成Get握手；dirty在T3可采样首个victim读 |
| BIU先收start再到B_GET/B_PUT才呈现A | B_IDLE启动直通，当周期呈现A；反压则保存payload；首D最早在首A握手后的下一拍接收 |
| 行缓冲就绪还经过WB_START | 直接进入WB_WAIT、呈现首Put；WB完成后直接转下一实际操作，无B_DONE派发空拍 |
| victim重复读取lookup已有双字，读节拍可能串行等待或多复制一次 | 有效lookup双字直接复用，只连续补读3拍；无可复用Data则4读。ECC直接寄存进行缓冲；单错收完在途读并修复后才发Put |
| CBO_ACTION/SCAN_NEXT/INV_ALL/BUS_FAIL/FINISH作为纯控制状态 | 改为当前状态内动作或完成事件；保留实际Tag写/修复/总线等待；CLEAN_ALL用dirty mask跳过空way |
| SC_CHECK、F_RESP和C_ACK可能被误写成额外等待 | 前台仅F_IDLE/F_WAIT，D等待用d_valid；SC接受前组合检查；CBO完成直接装ack/error，无两级完成状态 |
| 架构图/评审中残留旧接收及way寄存描述 | 删除末写沿接新DC请求、普通hit way选择额外寄存等矛盾描述 |

保留AMO已确认的额外流水拍、SRAM/ECC寄存、末次Data/Tag实际提交、脏行安全回写、single-outstanding及STB满时既定反压规则。WB应答W0后最早W1发Get，不要求旧D到新A组合直通。新增miss启动、首A握手后下一拍首D接收、victim连续读、单错收尾和1GHz路径均已加入RTL检查清单，当前仅完成文档级检查。

进入RTL前核对：

1. 外部行为已固定；LLD提供正常、miss、bus error、ECC和CBO收尾路径。
2. 首版单Load上下文、4+1 Store组织、无响应FIFO、固定LFSR伪随机替换均已同步。
3. 单错修复后AMO掩码写、CBO末拍错误汇总、drain转移瞬间可见性已列入实现和验证要求。
4. LLD v1.0作为最终review稿；本文不声称已得到用户对整份新增详细设计的最终批准，也不提前开始RTL。

以上段落记录2026-09-22文档评审当时的状态；2026-09-23已进入首版RTL实现和仿真，最新状态以本文末尾及RTL状态报告为准。

## 文档评审后的确认与合入（2026-09-22）

用户明确blocking边界：本模块只输出准确的`stb_drained_out`，上层Core等待该信号为1且前一笔blocking请求完成后才发送CBO。模块不得先锁存CBO再等待STB排空，不设置C_DRAIN；合法请求到达后接收、锁存并清reservation。原评审A1所依赖的忙时接收前提已移除，不采用额外的CBO→lr_killed补丁。

用户认可并已同步LLD、架构和图示的三项优化：

1. 普通Load hit T3无修复/维护/写冲突时同沿接受下一DC请求，主FSM直接进入新LOOKUP_ECC；旧结果仍从寄存数据输出。
2. 原子响应与DC工作分别记录完成，计入本沿事件后均完成即可同沿接受下一请求；SC reservation失败不等待不存在的owner_done。
3. 普通Store hit以纠正后完整数据形成1FF业务写，同时修复单错；不另加SCRUB，错误事件仍上报一次。

D路径已明确为寄存响应与直接响应的互斥选择；AMO miss旧值在关键字捕获后的下一沿直接握手，不在该沿再装最终D寄存器。用户已明确“按当前LLD”：确认C0捕获关键字、C1响应并寄存AMO运算/ECC结果、C2实际写SRAM；不将写入提前到C1。AMO miss写入边沿的待确认项关闭，关键beat后一个周期的mst D反压保持。该选择尚未经1GHz STA验证。

用户随后确认错误分界：关键beat及此前bus error返回零，之后beat错误均按晚到错误处理；例如关键beat成功准备结果1234，下一beat error与LSU D握手同沿，仍返回1234，该行不发布有效，不补发响应。已同步LLD、架构、refill修订及图示，并加入同沿注错验证要求。LLD以critical_err保存截至关键beat的错误，整笔err_seen独立控制安装/发布；LR/SC仍按整笔完成结果处理。

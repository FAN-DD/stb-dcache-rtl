# STB/DCache 文档逻辑、响应顺序与效率评审

日期：2026-09-22。范围：需求DOCX、当前顶层接口及宏/类型定义、LLD、架构稿、评审记录、refill修订、整体图及端口SVG。本文主体保留首次审阅时的发现，不替代LLD；后续处理状态见下表。首次审阅未修改设计，随后按用户答复同步了相关文档，未修改RTL。

| 项目 | 后续处理状态 |
| --- | --- |
| A1 CBO/LR交叠 | 用户明确不允许忙时接受CBO；已移除该假设，改为旧DC/前台完成后才接受并清reservation。原反例不再成立，不采用CBO置lr_killed方案 |
| A2错误分界 | 用户已确认并合入：关键beat及此前错误返回0；之后beat错误不改响应，含与LSU D握手同沿。LLD保存critical_err快照，整笔err_seen另行控制发布 |
| A3响应路径 | 已明确寄存/直接两路及AMO miss直接返回；用户确认保留当前LLD的C0捕获/C1响应并寄存AMO结果及ECC/C2实际写SRAM，不提前写入，A3关闭 |
| A4原子释放 | 已补前台两项完成记录、SC无owner失败及同沿释放/接收条件 |
| 三项用户认可优化 | Load hit T3接新DC请求、原子完成沿接新请求、Store完整码字写合并单错修复已合入 |

首次审阅结论：正常路径基本连贯，LSU D可保持A接受顺序；旧版“忙时先接收CBO”引入reservation交叠问题，另有周期和收尾描述缺口。该结论针对修订前版本，当前处理状态以上表及LLD为准。

## 1. 需要修正或明确的边界

### A1：CBO 接收可能无法持续清除在途 LR 的 reservation

依据：LLD 第 7 节规定 LR 执行期间的 `lr_killed` 记录 `lr_invalid`；第 8 节允许 DCache 忙时先接收 CBO，并在接收时清 reservation。第 9 节仅明确了同拍清除优先于建立。

可构造以下跨拍顺序：

1. LR miss 已接受，等待 refill。
2. （旧版问题场景，现已废止）CBO 被锁存，进入 C_DRAIN，清 reservation。
3. 较早 LR 完成；没有 lr_invalid，按当前规则重新建立 reservation。
4. CBO 随后执行、完成，但没有再次清 reservation 的明确动作。
5. 后续同址同 mask 的 SC 可能错误地通过 reservation 检查。

同拍优先级不能解决步骤 2、3 跨拍发生的情况。建议在 LR 活跃期间接受 CBO 时，同时置该 LR 的 `lr_killed`，完成时禁止建锁；LR 的数据响应仍正常返回。也可采用等价的维护执行时清锁规则，但应只保留一套明确的生命周期约定。

### A2：提前响应的错误分界尚未覆盖“响应与下一 beat 错误同沿”

依据：LLD 第 1 节和第 6.3 节说“响应前已知错误返回零”；第 3 节规定装载 D 时置 `response_issued`；第 6.3 节周期表则在 R1 装载关键结果、R2 才由 LSU 接收。

反例：关键 beat 在 R1 成功，D 寄存器已经装入非零结果；R2 同沿 LSU 接收该结果，而下一个 BIU beat 报错。若按 R1 已置 response_issued 处理，保留旧值；若按 R2 握手前的 err_next 处理，则可能返回零。两种解释会形成不同电路和可见结果。

首次审阅建议区分响应内容确定与LSU消费。用户现已确认以关键beat握手为界：保存截至该beat的累计错误，之后beat错误按晚到错误处理，避免增加后续BIU error到LSU D data的组合通路。上例仍返回R1确定的非零结果，仅使相关行不发布有效、不补发响应。已合入LLD及配套文档，A2关闭。

### A3：D 输出的寄存路径与直接输出路径需要明确分开

依据：LLD 第 3 节允许 hit 结果在 T3 直接握手；架构第 6.1 节也区分了寄存响应和 hit 直接响应。但整体图统一画为“单级 D 响应寄存器”，LLD 第 6.3 节对 AMO miss 使用“下一周期装载/完成旧值 D”的表述。

AMO miss 要求 C0 接收关键值、C1 完成 LSU D 握手。若 C1 才装入最终 D 寄存器，LSU 最早 C2 才接收，会额外增加一拍。因此应明确：

- Store Ack、STB 全转发 Load、普通 Load refill 等使用 D 寄存路径。
- 普通 Load hit、AMO hit，以及从 critical_old64 返回的 AMO miss 使用已寄存数据经组合选择输出，在指定沿直接握手。
- 总 D valid/data/source/size 由响应选择器统一生成；寄存路径与直接路径必须互斥，不以简单优先级静默丢弃其中一路。
- 旧直接响应消费与新寄存响应装载允许同沿发生；旧响应使用旧上下文，新响应保存新请求字段。
- AMO 直接响应也必须设置一次性响应标志；不能把“装载 D 寄存器”作为唯一的 response_issued 置位事件。

此项是把现有周期要求落实为明确数据通路，不需要增加 FIFO 或响应状态。

### A4：原子请求的两种完成顺序没有完整落实到寄存器生命周期

依据：LLD 第 4 节要求“响应已消费且 owner 已完成”才释放；第 5.3 节将 owner_done 定义为事件；第 3 节把 atomic_response_done 放在完成时释放的 refill 上下文内。第 4 节 front_valid_next 示例只展示普通 Load 释放。

至少要覆盖：

| 情况 | 事件顺序 | 必须明确的行为 |
| --- | --- | --- |
| AMO hit / 提前响应的 AMO miss | 先 d_fire，后 owner_done | 保存响应已消费状态，等待实际写入及协议收尾 |
| SC hit / SC miss | 先提交并装载成功 D，下一沿 d_fire | owner 完成事实在下一沿仍可判断，不能只等待一次性脉冲再次出现 |
| SC reservation 失败 | 不建立 SRAM/BIU owner，下一沿 d_fire | 按“无需 owner 工作且已完成”释放，不能等待不存在的 owner_done |
| LR 或原子错误收尾 | owner 完成与响应生成可能同沿，消费可能更晚 | 结果及释放条件保存到响应消费，不能提前丢弃 |

现有文字不证明一定会死锁，但不足以直接翻译成无歧义的 next-state。建议把原子响应已消费、owner 工作已结束定义为可跨拍判断的条件，统一处理无 owner 和同沿事件；可以使用前台标志，也可以在互斥保证下由 DC 空闲状态推导。旧上下文清除应低于同沿新请求捕获。

### A5：少量跨文档描述仍有漂移

- LLD 第 6.3 节“任何错误禁止 Tag 写和 Valid 发布”应限定为相关事务的 bus error，避免与已确定的“ECC 双错上报后继续”冲突。
- 架构第 12 节允许普通 Store 的完整码字写合并 Data 单错修复；LLD 第 5、6 节笼统要求普通 Store 单错先走 SCRUB。应明确是否采用一次业务写同时修复。
- CBO 上下文表写“ack 清 active”，第 8 节写“完成沿清 active 并装载 ack”。应统一为确定的边沿，避免多占一周期。
- 架构仍有 Tag raw 布局“需评审后固定”、BIU source“建议”等措辞，而评审/LLD 将部分内容作为固定约定。应按当前基线统一确定性用语。
- LFSR 已给种子、取样位和推进条件，但未给反馈多项式、移位方向及 next 公式。该项可由实现者补齐，不需要重新讨论替换算法。

## 2. 响应是否顺序

在 D ready 恒 1、每拍至多接受一条 LSU A、Load/原子占用前台及响应源互斥的前提下，正常路径没有发现必然的 D 乱序路径：

| 请求序列 | 响应顺序为何成立 |
| --- | --- |
| Store → Store | 每条 A 接受后下一沿返回 Ack；消费旧 Ack 与装载新 Ack 同沿，源信息随响应保存 |
| Store → Load | 最迟在 Load 接受沿消费前一 Store Ack；Load 结果最早再下一沿返回 |
| Load → Store | 后一 Store 最早在前一 Load 的 d_fire 沿接受，其 Ack 下一沿返回 |
| Load → STB 全转发 Load | 前一结果消费沿装载后一结果，下一沿才返回后一结果 |
| miss Load 提前返回 → 新请求 | 旧 owner 保留 response_issued，只完成 refill，不重复产生 D，也不访问已复用的前台响应字段 |
| AMO/LR/SC → 后续请求 | 前台等响应与 owner 工作均完成；不会让后续 D 越过该原子请求 |
| CBO 与已接受 LSU 请求重叠 | CBO 阻止新 A，等待旧前台及 D 完成；CBO Ack 是独立端口 |

例如连续 Store、全转发 Load、Store：

| 边沿 | A 接受 | D 消费 |
| --- | --- | --- |
| E0 | Store S0 | — |
| E1 | Store S1 | S0 Ack |
| E2 | 全转发 Load L2 | S1 Ack |
| E3 | Store S3 | L2 Data |
| E4 | — | S3 Ack |

这里的顺序指 LSU A/D 请求响应顺序，不表示每条 Store 都独立、按输入顺序写 SRAM 或写回主存。任意有效 entry 合并会把较新的 Store 合进较早条目；write-back 又会推迟主存更新。上述结论也不代替系统层面的内存模型验证。

## 3. 可优化空间及代价

| 建议 | 收益 | 条件与代价 |
| --- | --- | --- |
| 普通 Load hit 的 T3 同沿接下一次 DC 请求 | 连续 DC hit Load 的 T1 间隔可由当前 3 周期降为 2 周期 | 仅限旧请求已可完成、没有修复/维护/写 SRAM 冲突；T3 只输出旧寄存结果，SRAM 可采样新读。新增 hit/完成到 ready/读使能路径，须评估 1GHz 时序 |
| 已完成原子操作的响应消费沿接新请求 | 消除 SC 已提交、正在消费最终 D 等情况下的前台空档 | 必须确认原子写及完整收尾已经结束；AMO 提前 d_fire 不适用，当前仍在写的宏不能同时读 |
| 普通 Store hit 合并 Data 单错修复与业务写 | 省去一次独立 SCRUB 写 | 已有纠正后的完整 old64，业务写使用 wm=1FF；保留一次 ECC 上报。AMO hit 的掩码写修复约束不变 |
| 条件满足时抑制无用 Data 宏读取 | 降低动态功耗 | 例如 Tag-only 维护、全 invalid set 的无用 Data 读；不能把普通 Load 改成先读 Tag 再读 Data 而增加固定命中延迟 |

优先完成 A1–A5，再评估上述优化。普通 Load hit 同沿复用 SRAM 是吞吐收益最明确的一项，但不能仅凭周期图承诺 TSMC 22ULL下1GHz sign-off达标。当前保留下一周期再接 DC 请求属于明示的时序取舍，不是未说明的空转状态。

已有优化基本到位：STB 接受即提前应答、drain 接受即释放、普通 Load d_fire 同沿前台替换、关键 beat 提前响应、流式安装、miss 当拍发 Get、victim lookup 数据复用。没有理由重新加入响应 FIFO、MISS_SELECT、安装后 reload 或 FINISH 等纯控制等待。

## 4. 本次检查与后续验证

静态检查：端口 SVG 可解析，当前顶层声明的 61 个端口名称均在 SVG 中出现；docs 下 Markdown 本地链接无缺失目标。端口名覆盖和 XML 可解析不等同于所有图线方向、布局或功能已自动验证。

本次未运行 RTL 仿真、综合或 STA；顶层尚无主体实现。文档补齐后，验证至少增加：LR 在途时 CBO 接收、下一 BIU beat 报错与 LSU D 同沿、直接 D 响应同沿装载新寄存响应、SC 无 owner 失败、SC owner_done 早于 d_fire、旧 owner 收尾时前台上下文已复用，以及每条 A 恰有一次且按序的 D 检查。

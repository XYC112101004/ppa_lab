# ppa_lab
| 实验 1（Lab1） | 掌握 APB 3.0 从接口时序，实现 CSR 寄存器组与 SRAM 写入路径 |
| 实验 2（Lab2） | 掌握 FSM 设计，实现包头解析与格式检查算法核 |
| 实验 3（Lab3） | 掌握多模块集成方法，完成端到端驱动与结果验证 |
| 实验 4（Lab4） | 掌握回归测试与覆盖率闭环方法，完成完整验证收尾 |

Lab1：apb_slave_if + packet_sram（第 1–2 周）

**第 1 周（设计为主）**
- M1：APB 3.0 两段式时序 RTL；CTRL/CFG 可读写；STATUS/RES_* 只读直透（外部端口输入）；PKT_MEM 地址窗口 0x040–0x05C 译码
- M2：8×32-bit 双端口同步 SRAM RTL
- SV TB 骨架（时钟/复位/APB write/read 任务）

**第 2 周（验证为主）**
- CSR 默认值检查 testcase
- PKT_MEM 写入 testcase（监控 wr_en/addr/data）
- RES_* 读通路 testcase（外部 stub 赋值，APB 读回比对）
- 复用路科历史 Makefile/回归脚本，形成统一验收入口：make smoke / make regress / make cov

**必做验收项**

| # | 验收内容 | 关键判断 |
|---|---------|----------|
| 1 | APB 基础读写时序 | PSEL+PENABLE 两段式；PREADY 固定 1；读 CTRL/CFG/STATUS 默认值与规格一致 |
| 2 | PKT_MEM 写入地址映射 | APB 写 8 个 word 到 0x040–0x05C；波形显示 wr_en=1、wr_addr 按序递增、wr_data 匹配 |
| 3 | RES_* 寄存器读通路 | stub 赋值 res_pkt_len_i 等；APB 读 0x018/0x01C/0x020/0x024，PRDATA 与输入一致 |

**选做验收项**

| # | 验收内容 | 跨实验依赖 |
|---|---------|------------|
| 4 | PSLVERR 统一错误响应 | Lab3 选做 4 依赖此项 |
| 5 | IRQ 寄存器完整实现（IRQ_EN/IRQ_STA/irq_o） | Lab3 选做 5 依赖此项 |

Lab2：packet_proc_core（第 3–4 周）

**第 3 周（设计为主）**
- M3 3 态 FSM RTL；字计数器驱动 mem_rd_addr_o 递增
- 第 0 拍提取 pkt_len/pkt_type/flags/hdr_chk；pkt_len 范围检查 [4,32]
- res_pkt_len_o/res_pkt_type_o 在 DONE 态保持有效；busy_o/done_o 与 FSM 状态严格对应

**第 4 周（验证为主）**
- M3 独立 SV TB（用 SV 数组行为模型替代 M2，不依赖 Lab1 RTL）
- 正常包 / 长度越界 / 连续两帧 testcase；结果自动比对（差异自动打印 FAIL）

**必做验收项**

| # | 验收内容 | 关键判断 |
|---|---------|----------|
| 1 | 合法包完整处理 | start 后 done_o 拉高；res_pkt_len/type 正确；波形显示 IDLE→PROCESS→DONE |
| 2 | 长度越界检测 | pkt_len=3（下溢）和 pkt_len=33（上溢）时 length_error_o=1；M3 不卡死 |
| 3 | busy/done 时序 | start_i 有效后第 1 拍 busy_o=1；DONE 态 done_o 持续保持；再次 start 后 done_o 清零 |

**选做验收项**

| # | 验收内容 |
|---|---------|
| 4 | pkt_type 合法性 + type_mask 过滤（两种情形均需波形演示） |
| 5 | algo_mode=1 时 hdr_chk 校验；algo_mode=0 时旁路；payload sum/XOR 正确 |

Lab3：ppa_top 集成冒烟验证（第 5–6 周）

本次执行角色轮换：上一轮负责设计的同学本次负责验证，反之亦然。     
只要 Lab1/2 必做项完成即可顺利完成本次必做验收项。Lab1/2 选做未完成时 Lab3 选做 4/5 跳过，不影响必做评分。 

**第 5 周（集成设计）**
- ppa_top RTL 纯连线（M1↔M2 写端口、M3↔M2 读端口、M1→M3 控制信号、M3→M1 结果/状态），并统一将 PCLK/PRESETn 分发到 M1/M2/M3
- 集成 TB 复用 Lab1 APB 任务；建立端到端驱动序列（写 packet → 配置 CTRL → start → 轮询 STATUS.done → 读结果）

**第 6 周（集成验证）**
- 连续两帧场景驱动；修复集成发现的连线/接口缺陷；一键回归脚本

**必做验收项**

| # | 验收内容 | 关键判断 |
|---|---------|----------|
| 1 | 端到端链路完整 | 写合法 packet → start → 轮询 done=1 → APB 读 RES_PKT_LEN/TYPE 与写入一致 |
| 2 | 连续两帧顺序处理 | 两帧结果独立正确；done 信号在两帧间有清零过程 |
| 3 | STATUS 总线通路 | busy=1 时 STATUS[1:0]=2'b01；done=1 时 STATUS[1:0]=2'b10 |

**选做验收项**

| # | 验收内容 | 跨实验依赖 |
|---|---------|------------|
| 4 | busy 期间写 PKT_MEM 返回 PSLVERR；SRAM 内容不变 | 依赖 Lab1 选做 4 |
| 5 | 中断路径闭环（done_irq_en=1 → irq_o=1 → 清除 → irq_o=0） | 依赖 Lab1 选做 5 |

Lab4：集成回归与覆盖率闭环（第 7–8 周）

**第 7 周（回归与覆盖率建立）**
- 整理 Lab1–3 全部必做 testcase 为结构化回归列表
- 跑全量回归；统计 Questa line/branch/condition/FSM/toggle coverage 基线
- 分析覆盖率缺口；准备过滤清单（可过滤项先登记原因）

**第 8 周（缺陷修复与答辩准备）**
- 修复 RTL/TB 缺陷，确保一键 100% PASS
- coverage merge 生成最终 ucdb；导出 Questa HTML 覆盖率报告
- 整理 testplan 表格；准备现场答辩材料

**必做验收项**

| # | 验收内容 | 关键判断 |
|---|---------|----------|
| 1 | 一键回归通过率 100% | 助教当场执行 make regress，全部 PASS；Lab1–3 必做场景各有 ≥1 条对应 testcase |
| 2 | 五类覆盖率等级验收 | line + branch + condition + FSM + toggle；≥90% 合格 / ≥95% 优良 / 100% 优秀；Questa GUI 现场核验（不接受截图） |
| 3 | testplan 文档 | 表格含：testcase 名称 / 对应检查点 / 输入摘要 / 期望输出 / 结果（PASS/FAIL） |

**选做验收项**

| # | 验收内容 |
|---|---------|
| 4 | 覆盖率过滤合规：提交《覆盖率过滤登记表（Excel）》，逐条列明过滤对象/行数/原因/结论；未登记不得过滤 |
| 5 | 选做功能回归：将 Lab1–3 已完成的选做项纳入回归并全部 PASS；提供选做场景 testplan 条目 |

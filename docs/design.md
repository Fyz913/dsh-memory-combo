# 设计说明与验收

## 1. 问题

DSH 的记忆插件大致分两类：

- **自动型**（如 meow-memory）：对话即入库，首轮注入长期记忆，每条用户消息做关键词命中，空闲时整理。延迟低、几乎无感，但内存/上下文成本随条目增长。
- **认知图型**（如灵枢）：记忆是纯 md 文档，写入要过确定性规则（CCG 六要素、证据、权限），检索可解释、可审计。质量高，但每次写入都要显式发起。

两类都装、都开自动抓取，结果是：

1. 同一条对话被写两份；
2. 每轮注入两块内容，token 翻倍；
3. 两边内容各自演化，出现「哪份才是真的」的分叉。

## 2. 方案：按周期分工，只让一层自动

| 维度 | meow-memory | 灵枢 |
| --- | --- | --- |
| 时间尺度 | 分钟～天 | 周～年 |
| 触发 | 自动 | 显式 |
| 写入成本 | 低 | 高（六要素 + 校验） |
| 撤回 | 直接删 | 显式 forget，留审计 |
| 适合内容 | 项目细节、临时事实、教训 | 架构决策、身份、跨项目原则 |

关键开关只有一行：灵枢 `memory.userMessage: false`。

## 3. 写入纪律（agent 侧）

- 日常信息 → `memory_remember`（meow）。`project` 字段区分「全局 / 项目名」。
- 需要长期保留且能被审计的决策 → `cg(op="write", layer="knowledge")`（灵枢），正文必须是 CCG 六要素：

```
# 功能名：……
# 生效条件：……
# 子功能：……
# 执行：……
# 验证方式：……
# 不适用条件：……
```

缺任何一项都会被 `REJECT`，内容进 `rejected` 层，不污染知识库。

- 检索：短期用 `memory_search`（注意 `project` 层默认不参与，需 `level=project`）；长期用 `cg(op="read")` / `stg(op="timeline")`。

## 4. 验收清单

在 DSH 会话里依次执行（工具名以实际注册为准）：

1. `memory_remember(content="...", level="project", project="dsh", keywords=[...], importance=3)`
   → 返回 `id`
2. `memory_search(query="...", level="project")`
   → 能命中上一步的条目
3. `cg(op="write", content="<六要素>", layer="knowledge", importance=0.7)`
   → 返回 `committed: true`
4. `cg(op="read", query="...")`
   → 能读回第 3 步的节点
5. `scripts/verify.ps1` 全部通过

## 5. 已知取舍

- **双注入成本**：每轮两块注入。要省 token 可以只保留 meow 的注入，把灵枢当纯工具库（它仍会注入「最近记忆」，可在其配置里进一步收窄）。
- **两套存储不互通**：语义一致靠写作纪律，不靠系统同步。
- **灵枢需要 Python**：包内自带 `md_cg`，但解释器必须在 PATH；Windows 默认找 `python`。
- **meow 的记忆在 workspace 内**：换工作区就是换记忆库（这是它的项目隔离设计）。
- **卸载不删数据**：两个数据目录都要手动清理。

## 6. 目录

```
dsh-memory-combo/
├─ README.md
├─ NOTICE.md
├─ LICENSE
├─ patch/cordis.patch.yml.example
├─ scripts/install.ps1
├─ scripts/verify.ps1
└─ docs/design.md
```

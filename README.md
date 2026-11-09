# dsh-memory-combo · DSH 双记忆组合

把 **meow-memory**（自动层）和 **灵枢 Lingshu**（深度层）组合成一套双记忆系统的配置配方。

> 这不是一个新插件，也不包含这两款插件的源码。仓库提供的是：**分工设计 + 安装脚本 + profile 配置片段 + 验收清单**。

## 为什么需要两个

单一记忆系统很难同时满足两种需求：

| 需求 | 特点 | 适合的层 |
| --- | --- | --- |
| 日常对话、项目细节、短期上下文 | 高频、自动、要求延迟低 | meow-memory |
| 架构决策、身份认知、可审计的长期事实 | 低频、显式、要求可追溯 | 灵枢 |

硬叠两个会造成「双份自动抓取 + 双份注入」。本仓库的方案是**关掉一边的自动抓取**，让它只做显式调用。

## 分工

| | meow-memory | 灵枢 Lingshu |
| --- | --- | --- |
| 定位 | 自动工作记忆 | 深度认知图 |
| 采集 | 自动（对话即入库） | **关闭自动抓取** |
| 注入 | 首轮长期记忆 + 每消息关键词命中 | 最近记忆块 |
| 存储 | `<workspace>/.dsh-meow/memory.db`（SQLite） | `$DSH_HOME/.dsh-memory/data/mdcg`（md 认知图） |
| 工具 | `memory_remember` / `search` / `project` / `dream` … | `cg` / `stg`（`tools: core`） |
| 写入门槛 | 直接写 | **fail-closed**：必须补齐 CCG 六要素 |

## 安装

前置：DSH 0.2.x，profile 为 `desktop`（其它 profile 把参数改掉即可）。

```powershell
# 1) meow-memory（自动层）
dsh plugin --profile desktop add meow-memory@0.32.6

# 2) 灵枢（深度层，需要本机 Python ≥ 3.10，包内自带 md_cg，无需 pip 装第三方包）
dsh plugin --profile desktop add "@furongjun1999/dsh-memory@0.9.23"

# 3) 写入分工配置：把 patch/cordis.patch.yml.example 的内容合并进
#    $DSH_HOME/profiles/desktop/cordis.patch.yml

# 4) 重启 DSH
```

桌面版也可以直接在「插件 → 添加插件」里输入两个包名，再把配置片段粘进 profile 的 `cordis.patch.yml`。

## 配置要点

```yaml
- id: meow-memory
  name: meow-memory
  config:
    enabled: true
    promptLang: zh          # 不写会静默落回 zh，但建议显式
    hitTopK: 2              # 每条消息最多命中 2 条
    dream:
      enabled: true
      idleMinutes: 180      # 空闲 3 小时整理

- id: furongjun1999-dsh-memory
  name: "@furongjun1999/dsh-memory"
  config:
    serverName: lingshu
    tools: core             # 只暴露 cg / stg
    memory:
      userMessage: false    # ★ 关键：关掉自动抓取，避免与 meow 双写
      assistantMessage: false
      toolResult: false
    mutual:
      enabled: false        # 单实例不需要互维心跳
    mdcg:
      enabled: true
```

## 验收

```powershell
# meow：写入后按 project 层检索（project 层默认不参与关键词检索，必须显式传 level）
# 在会话里调用 memory_remember(level="project")，再 memory_search(query="...", level="project")

# 灵枢：写入必须带 CCG 六要素，否则被拒收
# cg(op="write", content="""# 功能名：...
# # 生效条件：...
# # 子功能：...
# # 执行：...
# # 验证方式：...
# # 不适用条件：...""", layer="knowledge", importance=0.7)
# 然后 cg(op="read", query="...")
```

详见 [docs/design.md](docs/design.md)。

## 已知代价

- **每轮两块注入**：灵枢「最近记忆」+ meow「近期对话」，大约每轮多几百到上千 token。
- **灵枢写入 fail-closed**：正文不补齐六要素会被 `REJECT`，拒收记录留在 `rejected` 层，不占知识库。
- **meow 的 project 层不参与默认检索**：查它必须显式 `level=project`。
- **两套存储各自独立**：不做互相同步；语义一致靠 agent 写作纪律，不靠系统。

## 卸载

```powershell
dsh plugin --profile desktop remove meow-memory
dsh plugin --profile desktop remove "@furongjun1999/dsh-memory"
```

数据目录（`<workspace>/.dsh-meow/`、`$DSH_HOME/.dsh-memory/`）不会自动删除，需要手动清理。

## 许可

本仓库的文档、脚本与配置片段以 MIT 发布。两款插件各自独立授权，见 [NOTICE.md](NOTICE.md)。

# 🦞 Clawd - OpenClaw 新手一键配置启动包

> **让 OpenClaw 配置变得简单！** 下载本项目，即可获得预配置好的 OpenClaw 工作区，
> 包含精选 Skills、完善的中文文档和最佳实践配置。

[![OpenClaw](https://img.shields.io/badge/OpenClaw-Compatible-blue)](https://docs.openclaw.ai)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-green)](https://docs.openclaw.ai/platforms)
[![Language](https://img.shields.io/badge/Language-中文-red)](./docs/OPENCLAW_GUIDE.md)

---

## 这是什么？

**Clawd** 是一个预配置好的 [OpenClaw](https://github.com/openclaw/openclaw) 工作区模板。

OpenClaw 是一个运行在本地的 AI 助手平台，支持通过 WhatsApp、Telegram、飞书、Discord 等通讯渠道与 AI 交互。但它的初始配置对新手来说比较复杂。

**本项目解决的问题：**
- 开箱即用的 Agent 身份和行为配置
- 预装经过筛选的实用 Skills（技能）
- 完整的中文文档和配置教程
- 飞书通道配置指南
- 一键 Skills 安装脚本

---

## 快速开始

### 前置条件

1. 已安装 [Node.js](https://nodejs.org) ≥ 22
2. 已安装 OpenClaw：
   ```bash
   npm install -g openclaw@latest
   openclaw onboard --install-daemon
   ```

### 使用本项目

```bash
# 1. 克隆项目到本地
git clone https://github.com/nio1112/openclaw.git
cd openclaw

# 2. 一键安装所有推荐 Skills（PowerShell）
.\scripts\install-skills.ps1

# 3. 自定义你的配置
#    编辑以下文件：
#    - USER.md     → 填写你的个人信息
#    - IDENTITY.md → 自定义 AI 助手身份（可选）

# 4. 将此目录设为 OpenClaw 工作区
openclaw config set agents.defaults.workspace "$(pwd)"

# 5. 重启 Gateway
openclaw gateway restart
```

---

## 项目结构

```
clawd/
├── AGENTS.md              # Agent 行为规则（每次会话加载）
├── SOUL.md                # Agent 核心人格定义
├── IDENTITY.md            # Agent 身份（名称、风格、emoji）
├── USER.md                # 你的个人信息（需自定义）
├── TOOLS.md               # 环境特定的工具配置
├── MEMORY.md              # 长期记忆（仅主会话加载）
├── HEARTBEAT.md           # 心跳检查任务
│
├── memory/                # 每日记忆日志
│   ├── YYYY-MM-DD.md
│   └── reddit-preferences.md
│
├── skills/                # 已安装的 Skills
│   ├── summarize/         # 文本/网页摘要
│   ├── weather/           # 天气查询
│   ├── blogwatcher/       # 博客/RSS 监控
│   ├── git-essentials/    # Git 常用命令
│   ├── deepwiki/          # GitHub 文档查询
│   ├── skill-creator/     # 技能创建向导
│   └── ...                # 更多 Skills
│
├── docs/                  # 文档
│   ├── OPENCLAW_GUIDE.md  # OpenClaw 完整学习指南
│   ├── PROJECT_ANALYSIS.md # 项目深度分析
│   └── FEISHU_SETUP.md    # 飞书通道配置指南
│
├── scripts/               # 工具脚本
│   └── install-skills.ps1 # Skills 批量安装脚本
│
└── .openclaw/             # 工作区状态文件
```

---

## 预装 Skills 清单

### 已包含的 Skills

| 技能 | 功能 | 来源 |
|------|------|------|
| `summarize` | 文本/网页内容摘要 | 内置 |
| `weather` | 天气查询 | 内置 |
| `blogwatcher` | 博客/RSS 监控 | 内置 |
| `skill-creator` | 创建新技能的向导 | 内置 |
| `git-essentials` | Git 常用命令 | ClawHub |
| `conventional-commits` | 规范化提交信息 | ClawHub |
| `deepwiki` | GitHub 文档查询 | ClawHub |
| `feishu-card` | 飞书富文本交互卡片 | ClawHub |

### 推荐额外安装

通过 `scripts/install-skills.ps1` 可以一键安装以下推荐 Skills：

| 技能 | 功能 |
|------|------|
| `conventional-commits` | 规范化 Git 提交信息 |
| `baidu-search` | 百度搜索（中文友好） |
| `bing-search` | Bing 搜索 |
| `ai-daily-briefing` | 每日工作简报 |
| `docx` | Word 文档生成/编辑 |
| `image-ocr` | 图片文字识别 (OCR) |
| `feishu-card` | 飞书富文本卡片 |
| `feishu-memory-recall` | 飞书记忆恢复 |
| `arxiv-watcher` | ArXiv 论文搜索 |
| `agent-memory` | 持久化记忆系统 |

> 更多 Skills 请浏览：[Awesome OpenClaw Skills](https://github.com/VoltAgent/awesome-openclaw-skills)

---

## 通讯渠道配置

### 飞书 (Feishu/Lark)

详细配置指南请查看：[📖 飞书配置教程](./docs/FEISHU_SETUP.md)

快速步骤：
1. 安装飞书插件：`openclaw plugins install @openclaw/feishu`
2. 在飞书开放平台创建应用
3. 配置 `openclaw.json`
4. 重启 Gateway

### 其他渠道

OpenClaw 还支持以下通讯渠道（参考 [官方文档](https://docs.openclaw.ai/channels)）：

- [Telegram](https://docs.openclaw.ai/channels/telegram)
- [WhatsApp](https://docs.openclaw.ai/channels/whatsapp)
- [Discord](https://docs.openclaw.ai/channels/discord)
- [Slack](https://docs.openclaw.ai/channels/slack)
- [微信 (WeChat)](https://docs.openclaw.ai/channels)
- [WebChat](https://docs.openclaw.ai/web/webchat) — 开箱即用

---

## 自定义配置

### 修改 Agent 身份

编辑 `IDENTITY.md`，自定义 AI 助手的：
- 名称
- 形象（AI 助手、数字宠物、机器人等）
- 沟通风格
- 签名 Emoji

### 填写你的信息

编辑 `USER.md`，告诉 AI 关于你的：
- 名字和称呼方式
- 时区
- 回复语言偏好
- 工作/兴趣领域

### 修改系统配置

主配置文件位于 `~/.openclaw/openclaw.json`（或 `moltbot.json`），可配置：
- AI 模型选择
- Gateway 端口
- 通道连接
- 技能开关
- 安全策略

> 详细配置说明请参考：[📖 OpenClaw 完整学习指南](./docs/OPENCLAW_GUIDE.md)

---

## 文档索引

| 文档 | 说明 |
|------|------|
| [OpenClaw 完整学习指南](./docs/OPENCLAW_GUIDE.md) | 涵盖架构、配置、Skills、CLI 等 12 章节 |
| [项目深度分析](./docs/PROJECT_ANALYSIS.md) | 当前配置状态评估和改进建议 |
| [飞书配置教程](./docs/FEISHU_SETUP.md) | 飞书 Bot 完整接入指南 |
| [官方文档](https://docs.openclaw.ai) | OpenClaw 官方文档 |
| [Awesome Skills](https://github.com/VoltAgent/awesome-openclaw-skills) | 社区 Skills 合集 |
| [ClawHub](https://clawhub.com) | 技能市场 |

---

## 常见问题

### Q: 如何更新已安装的 Skills？
```bash
npx clawhub@latest update --all --workdir "D:\home\node\clawd"
```

### Q: 如何添加新 Skill？
```bash
npx clawhub@latest search "关键词"
npx clawhub@latest install <skill-slug> --workdir "D:\home\node\clawd"
```

### Q: Gateway 出问题怎么办？
```bash
openclaw doctor --fix
```

### Q: 如何查看当前状态？
```bash
openclaw status --all
```

---

## 贡献

欢迎提交 Issue 和 PR 来改进这个启动包！

- 推荐好用的 Skills
- 改进文档翻译
- 分享配置最佳实践
- 报告问题

---

## 许可证

本项目配置和文档采用 MIT 许可证。
OpenClaw 本身的许可证请参考 [官方仓库](https://github.com/openclaw/openclaw)。

---

*Made with 🦞 by NIO.L*

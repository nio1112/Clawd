# OpenClaw 完整学习指南

> 整理时间：2026-02-24
> 项目地址：https://github.com/nio1112/openclaw
> 官方文档：https://docs.openclaw.ai
> 深度 Wiki：https://deepwiki.com/openclaw/openclaw

---

## 一、项目概览

### 1.1 是什么

OpenClaw（🦞）是一个**个人 AI 助手平台**，运行在你自己的设备上。它的核心理念是：
- **本地优先（Local-first）**：Gateway 运行在本地，数据不离开你的设备
- **多通道统一收件箱**：通过你已有的通讯渠道（WhatsApp、Telegram、Slack、Discord、微信等）与 AI 交互
- **可扩展技能系统**：通过 Skills 扩展 AI 能力
- **跨平台支持**：macOS、Linux、Windows（WSL2）

### 1.2 定位

OpenClaw 不是一个简单的聊天机器人。它是一个具备**持久记忆、主动行为、工具调用能力**的完整 AI 助手系统。Gateway 是控制平面，产品核心是助手本身。

### 1.3 核心亮点

| 特性 | 说明 |
|------|------|
| 本地 Gateway | 单一 WebSocket 控制平面，管理 sessions、channels、tools 和 events |
| 多通道收件箱 | WhatsApp, Telegram, Slack, Discord, Google Chat, Signal, iMessage, MS Teams, WebChat 等 |
| 多 Agent 路由 | 将入站频道/账户路由到隔离的 Agent（独立 workspace + 会话） |
| Voice Wake + Talk Mode | macOS/iOS/Android 的语音唤醒和对话模式（ElevenLabs） |
| Live Canvas | Agent 驱动的可视化工作区（A2UI） |
| 一流工具支持 | 浏览器控制、Canvas、Nodes、Cron、Sessions、Discord/Slack 操作 |
| 伴侣 App | macOS 菜单栏 + iOS/Android 节点 |
| Skills 系统 | 向导式设置 + 内置/托管/工作区技能 |
| ClawHub | 技能市场（clawhub.com） |

---

## 二、系统架构

### 2.1 架构概览

```
WhatsApp / Telegram / Slack / Discord / Google Chat / Signal / iMessage / ...
                          │
                          ▼
              ┌───────────────────────────────┐
              │          Gateway              │
              │      (控制平面 / WS)          │
              │   ws://127.0.0.1:18789        │
              └──────────────┬────────────────┘
                             │
                 ┌───────────┼──────────────┐
                 │           │              │
          ┌──────┴──┐ ┌─────┴─────┐ ┌──────┴──────┐
          │ Pi Agent│ │ CLI 工具  │ │ WebChat UI  │
          │  (RPC)  │ │           │ │             │
          └─────────┘ └───────────┘ └─────────────┘
                             │
                    ┌────────┼────────┐
                    │                 │
              ┌─────┴─────┐   ┌──────┴──────┐
              │ macOS App │   │ iOS/Android  │
              │           │   │   Nodes      │
              └───────────┘   └─────────────┘
```

### 2.2 关键子系统

| 子系统 | 功能 |
|--------|------|
| **Gateway WebSocket** | 单一 WS 控制平面，管理客户端、工具和事件 |
| **Pi Agent Runtime** | RPC 模式运行的 Agent，支持工具流和块流 |
| **Session Model** | `main` 用于直接聊天，群组隔离，激活模式，队列模式 |
| **Media Pipeline** | 图片/音频/视频处理，转录，大小限制，临时文件 |
| **Browser Control** | 专用 Chrome/Chromium，CDP 控制 |
| **Canvas + A2UI** | Agent 驱动的可视化工作区 |
| **Nodes** | 摄像头/屏幕录制/位置获取/通知 |
| **Skills Platform** | 内置/托管/工作区技能 + 安装门控 + UI |

### 2.3 数据流

1. 用户通过**通讯渠道**发送消息
2. Gateway 接收并路由到对应的 **Session**
3. Pi Agent 处理消息，调用**工具**（bash、browser、cron 等）
4. Agent 将响应通过 Gateway 回传到对应**通道**

---

## 三、安装与部署

### 3.1 系统要求

- **运行时**: Node.js ≥ 22
- **Windows**: 需要 WSL2（强烈推荐）
- **包管理器**: npm / pnpm / bun（推荐 pnpm 用于源码构建）

### 3.2 推荐安装（npm 全局）

```bash
npm install -g openclaw@latest
# 或
pnpm add -g openclaw@latest

# 运行 onboarding 向导
openclaw onboard --install-daemon
```

### 3.3 从源码安装

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build        # 首次运行自动安装 UI 依赖
pnpm build
openclaw onboard --install-daemon

# 开发模式（TS 变更自动重载）
pnpm gateway:watch
```

### 3.4 Windows (WSL2) 安装步骤

1. **安装 WSL2 + Ubuntu**:
   ```powershell
   wsl --install
   # 或指定发行版
   wsl --install -d Ubuntu-24.04
   ```

2. **启用 systemd**（Gateway 安装必需）:
   ```bash
   sudo tee /etc/wsl.conf >/dev/null <<'EOF'
   [boot]
   systemd=true
   EOF
   ```
   然后 `wsl --shutdown` 重启 WSL

3. **在 WSL 内安装 OpenClaw**:
   ```bash
   npm install -g openclaw@latest
   openclaw onboard --install-daemon
   ```

### 3.5 升级

```bash
openclaw update --channel stable|beta|dev
openclaw doctor  # 运行诊断
```

### 3.6 版本通道

| 通道 | 说明 | npm tag |
|------|------|---------|
| stable | 标记发布（vYYYY.M.D） | `latest` |
| beta | 预发布（vYYYY.M.D-beta.N） | `beta` |
| dev | main 分支最新 | `dev` |

---

## 四、配置系统

### 4.1 配置文件位置

主配置文件：`~/.openclaw/openclaw.json`（或旧名 `moltbot.json`）

> **注意**：配置使用 JSON5 格式，支持注释和尾部逗号。

### 4.2 配置编辑方式

| 方式 | 命令/说明 |
|------|-----------|
| 交互式向导 | `openclaw onboard` / `openclaw configure` |
| CLI 单行命令 | `openclaw config set/get/unset <key> <value>` |
| 控制 UI | http://127.0.0.1:18789 |
| 直接编辑 | 编辑 `~/.openclaw/openclaw.json`，保存后热重载 |

### 4.3 最小配置示例

```json5
{
  agent: {
    model: "anthropic/claude-opus-4-6",
  },
}
```

### 4.4 常用配置项

#### 模型配置

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "anthropic/claude-sonnet-4-5",
        fallbacks: ["openai/gpt-5.2"],
      },
      models: {
        "anthropic/claude-sonnet-4-5": { alias: "Sonnet" },
        "openai/gpt-5.2": { alias: "GPT" },
      },
    },
  },
}
```

#### 通道配置（以 Telegram 为例）

```json5
{
  channels: {
    telegram: {
      enabled: true,
      botToken: "123:abc",
      dmPolicy: "pairing",  // pairing | allowlist | open | disabled
      allowFrom: ["tg:123"],
    },
  },
}
```

#### 会话配置

```json5
{
  session: {
    dmScope: "per-channel-peer",
    threadBindings: {
      enabled: true,
      ttlHours: 24,
    },
    reset: {
      mode: "daily",
      atHour: 4,
      idleMinutes: 120,
    },
  },
}
```

#### 心跳配置

```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "30m",   // 设置 "0m" 禁用
        target: "last", // last | whatsapp | telegram | discord | none
      },
    },
  },
}
```

#### Cron 任务配置

```json5
{
  cron: {
    enabled: true,
    maxConcurrentRuns: 2,
    sessionRetention: "24h",
    runLog: {
      maxBytes: "2mb",
      keepLines: 2000,
    },
  },
}
```

#### 沙箱配置

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "non-main",  // off | non-main | all
        scope: "agent",    // session | agent | shared
      },
    },
  },
}
```

#### Gateway 配置

```json5
{
  gateway: {
    port: 18789,
    mode: "local",
    bind: "loopback",
    auth: {
      mode: "token",
      token: "your-secret-token",
    },
  },
}
```

### 4.5 配置热重载

修改 `openclaw.json` 后，Gateway 会自动检测变化并热重载。

**可热重载的配置**：
- 通道设置
- 模型配置
- 心跳间隔
- Skills 配置

**需要重启的配置**：
- Gateway 端口
- 绑定模式
- 认证模式

---

## 五、Workspace（工作区）

### 5.1 工作区结构

```
~/.openclaw/workspace/        # 默认工作区根目录（可通过 agents.defaults.workspace 自定义）
├── AGENTS.md                 # 工作区规则（Agent 每次会话启动时读取）
├── SOUL.md                   # Agent 的身份和人格定义
├── IDENTITY.md               # Agent 的名字、形象、风格
├── USER.md                   # 用户信息（名字、时区、偏好）
├── TOOLS.md                  # 本地工具配置笔记
├── BOOTSTRAP.md              # 首次运行引导（完成后删除）
├── HEARTBEAT.md              # 心跳检查任务列表
├── MEMORY.md                 # 长期记忆（仅主会话加载）
├── memory/                   # 每日记忆日志
│   ├── YYYY-MM-DD.md
│   └── heartbeat-state.json
├── skills/                   # 工作区技能
│   └── <skill-name>/
│       └── SKILL.md
└── .openclaw/                # 工作区状态
    └── workspace-state.json
```

### 5.2 核心 Markdown 文件说明

| 文件 | 用途 | 加载时机 |
|------|------|----------|
| `AGENTS.md` | Agent 的行为规则和约定 | 每次会话 |
| `SOUL.md` | Agent 的身份、人格和边界 | 每次会话 |
| `USER.md` | 用户信息和偏好 | 每次会话 |
| `IDENTITY.md` | Agent 的名字、形象、Emoji | 每次会话 |
| `TOOLS.md` | 本地环境相关的工具笔记 | 每次会话 |
| `BOOTSTRAP.md` | 首次运行引导脚本 | 仅首次 |
| `HEARTBEAT.md` | 心跳检查清单 | 心跳轮询 |
| `MEMORY.md` | 长期记忆（策划的知识） | 仅主会话 |

### 5.3 记忆系统

- **每日笔记** (`memory/YYYY-MM-DD.md`): 原始事件日志
- **长期记忆** (`MEMORY.md`): 精选的关键信息
- **心跳状态** (`memory/heartbeat-state.json`): 周期检查追踪

记忆维护原则：
1. 每日文件是「原始笔记」，MEMORY.md 是「精选智慧」
2. 定期审查日志，将重要内容提炼到 MEMORY.md
3. 清理过时信息

---

## 六、Skills（技能系统）

### 6.1 概述

Skills 是 OpenClaw 的扩展能力系统。每个 Skill 是一个包含 `SKILL.md` 的目录，定义了 Agent 可以执行的特定任务。

### 6.2 Skills 位置与优先级

| 优先级 | 位置 | 说明 |
|--------|------|------|
| 1（最高） | 内置 skills | 随 npm 包或 OpenClaw.app 附带 |
| 2 | 托管/本地 skills | `~/.openclaw/skills/` |
| 3 | 工作区 skills | `<workspace>/skills/` |
| 4（最低） | 额外目录 | `skills.load.extraDirs` 配置 |

### 6.3 SKILL.md 格式

```markdown
---
name: my-skill
description: 技能的简短描述
metadata: { "openclaw": { "requires": { "bins": ["tool-name"] }, "primaryEnv": "API_KEY_NAME" } }
---

# 技能名称

详细的使用说明和工作流程...
```

#### Frontmatter 可选字段

| 字段 | 说明 |
|------|------|
| `homepage` | 技能的网站 URL |
| `user-invocable` | `true/false`（默认 true），是否作为斜杠命令暴露 |
| `disable-model-invocation` | `true/false`（默认 false），是否从 prompt 中排除 |
| `command-dispatch` | `tool`，斜杠命令直接调度到工具 |
| `command-tool` | dispatch 模式下要调用的工具名 |
| `command-arg-mode` | `raw`（默认），转发原始参数 |

#### metadata.openclaw 门控字段

| 字段 | 说明 |
|------|------|
| `always: true` | 始终包含该技能 |
| `emoji` | UI 显示的 emoji |
| `homepage` | 网站 URL |
| `os` | 平台限制（darwin/linux/win32） |
| `requires.bins` | 必须在 PATH 中的二进制文件 |
| `requires.anyBins` | PATH 中至少有一个 |
| `requires.env` | 必需的环境变量 |
| `requires.config` | openclaw.json 中必须为 truthy 的路径 |
| `primaryEnv` | 关联 `skills.entries.<name>.apiKey` 的环境变量 |
| `install` | 安装器规格数组（brew/node/go/uv/download） |

### 6.4 Skills 配置（openclaw.json）

```json5
{
  skills: {
    entries: {
      "nano-banana-pro": {
        enabled: true,
        apiKey: "YOUR_KEY",
        env: {
          GEMINI_API_KEY: "YOUR_KEY",
        },
        config: {
          endpoint: "https://example.com",
          model: "nano-pro",
        },
      },
      peekaboo: { enabled: true },
      sag: { enabled: false },
    },
    load: {
      watch: true,           // 自动监视变更
      watchDebounceMs: 250,
    },
    install: {
      nodeManager: "npm",    // npm/pnpm/yarn/bun
    },
  },
}
```

### 6.5 内置 Skills 清单（Bundled）

以下是 OpenClaw 仓库中附带的所有内置技能：

| 技能名 | 说明 | 适用平台 |
|--------|------|----------|
| `1password` | 1Password 密码管理集成 | 全平台 |
| `apple-notes` | Apple Notes 笔记操作 | macOS |
| `apple-reminders` | Apple 提醒事项操作 | macOS |
| `bear-notes` | Bear Notes 笔记操作 | macOS |
| `blogwatcher` | 博客监控与追踪 | 全平台 |
| `bluebubbles` | iMessage 集成（BlueBubbles） | macOS |
| `camsnap` | 摄像头拍照/录像 | macOS/iOS |
| `canvas` | A2UI 可视化工作区 | macOS/iOS/Android |
| `clawhub` | ClawHub 技能市场 CLI | 全平台 |
| `coding-agent` | 编码助手 Agent | 全平台 |
| `discord` | Discord 频道操作 | 全平台 |
| `gemini` | Gemini CLI 编码与搜索 | 全平台 |
| `gh-issues` | GitHub Issues 管理 | 全平台 |
| `gifgrep` | GIF 搜索 | 全平台 |
| `github` | GitHub 仓库操作 | 全平台 |
| `gog` | Google 搜索 | 全平台 |
| `goplaces` | Google Places 地点搜索 | 全平台 |
| `healthcheck` | 系统健康检查 | 全平台 |
| `himalaya` | Himalaya 邮件客户端集成 | 全平台 |
| `imsg` | iMessage 旧版集成 | macOS |
| `mcporter` | MCP 工具导入器 | 全平台 |
| `model-usage` | 模型使用量追踪 | 全平台 |
| `nano-banana-pro` | Gemini Pro 图片生成/编辑 | 全平台 |
| `nano-pdf` | PDF 处理 | 全平台 |
| `notion` | Notion 集成 | 全平台 |
| `obsidian` | Obsidian 笔记集成 | 全平台 |
| `openai-image-gen` | OpenAI 图片生成 | 全平台 |
| `openai-whisper` | OpenAI Whisper 语音转文字（本地） | 全平台 |
| `openai-whisper-api` | OpenAI Whisper API 语音转文字 | 全平台 |
| `openhue` | Philips Hue 智能灯光控制 | 全平台 |
| `oracle` | Oracle 数据库操作 | 全平台 |
| `ordercli` | 订单 CLI 工具 | 全平台 |
| `peekaboo` | 屏幕截图（macOS） | macOS |
| `sag` | ElevenLabs TTS 语音合成 | 全平台 |
| `session-logs` | 会话日志管理 | 全平台 |
| `sherpa-onnx-tts` | 本地 TTS 语音合成 | 全平台 |
| `skill-creator` | 技能创建向导 | 全平台 |
| `slack` | Slack 操作 | 全平台 |
| `songsee` | 音乐识别 | 全平台 |
| `sonoscli` | Sonos 音响控制 | 全平台 |
| `spotify-player` | Spotify 播放控制 | 全平台 |
| `summarize` | 文本/网页摘要 | 全平台 |
| `things-mac` | Things 任务管理 | macOS |
| `tmux` | Tmux 终端管理 | Linux/macOS |
| `trello` | Trello 看板操作 | 全平台 |
| `video-frames` | 视频帧提取 | 全平台 |
| `voice-call` | 语音通话 | macOS/iOS |
| `wacli` | WhatsApp CLI 工具 | 全平台 |
| `weather` | 天气查询 | 全平台 |
| `xurl` | URL 内容提取 | 全平台 |

### 6.6 ClawHub（技能市场）

ClawHub 是 OpenClaw 的公共技能注册中心。

**安装 CLI**：
```bash
npm i -g clawhub
# 或
pnpm add -g clawhub
```

**常用命令**：
```bash
# 搜索技能
clawhub search "calendar"

# 安装技能
clawhub install <skill-slug>

# 更新所有已安装技能
clawhub update --all

# 列出已安装技能
clawhub list

# 发布技能
clawhub publish ./my-skill --slug my-skill --name "My Skill" --version 1.0.0

# 同步所有
clawhub sync --all
```

---

## 七、CLI 命令参考

### 7.1 Gateway 管理

```bash
openclaw onboard              # 交互式 onboarding 向导
openclaw onboard --install-daemon  # 安装为守护进程
openclaw configure             # 配置向导
openclaw gateway --port 18789  # 启动 Gateway
openclaw gateway install       # 安装 Gateway 服务
openclaw doctor                # 诊断问题
openclaw doctor --fix           # 自动修复问题
openclaw status --all           # 查看完整状态
openclaw health                 # 健康检查
openclaw logs                   # 查看日志
openclaw update --channel stable  # 更新
```

### 7.2 配置管理

```bash
openclaw config get agents.defaults.workspace
openclaw config set agents.defaults.heartbeat.every "2h"
openclaw config unset tools.web.search.apiKey
```

### 7.3 消息发送

```bash
openclaw message send --to +1234567890 --message "Hello"
openclaw agent --message "Ship checklist" --thinking high
```

### 7.4 聊天命令（在通道内使用）

| 命令 | 说明 |
|------|------|
| `/status` | 查看会话状态（模型+tokens） |
| `/new` 或 `/reset` | 重置会话 |
| `/compact` | 压缩会话上下文 |
| `/think <level>` | 设置思考级别：off/minimal/low/medium/high/xhigh |
| `/verbose on\|off` | 开关详细模式 |
| `/usage off\|tokens\|full` | 用量显示控制 |
| `/restart` | 重启 Gateway（仅群组所有者） |
| `/activation mention\|always` | 群组激活模式 |

---

## 八、安全模型

### 8.1 安全默认值

- **主会话**：工具在主机上运行，Agent 拥有完全访问权限
- **非主会话**（群组/通道）：建议启用沙箱模式
- **沙箱默认白名单**：`bash`, `process`, `read`, `write`, `edit`, `sessions_*`
- **沙箱默认黑名单**：`browser`, `canvas`, `nodes`, `cron`, `discord`, `gateway`

### 8.2 DM 访问策略

| 策略 | 说明 |
|------|------|
| `pairing`（默认） | 未知发送者收到配对码，需要 `openclaw pairing approve` 批准 |
| `allowlist` | 仅允许 `allowFrom` 列表中的发送者 |
| `open` | 允许所有 DM（需要 `allowFrom: ["*"]`） |
| `disabled` | 忽略所有 DM |

### 8.3 安全最佳实践

1. **第三方 Skills 视为不信任代码**，启用前务必阅读
2. 使用**沙箱模式**运行不信任的输入和高风险工具
3. **secrets** 通过 `skills.entries.*.env` 注入，保持在 prompts 和日志之外
4. 定期运行 `openclaw doctor` 检查安全配置

---

## 九、通道支持

### 9.1 完整通道列表

| 通道 | 配置键 | 说明 |
|------|--------|------|
| WhatsApp | `channels.whatsapp` | Baileys 库，扫码登录 |
| Telegram | `channels.telegram` | grammY 库，BotFather 创建 |
| Slack | `channels.slack` | Bolt 库，需要 Bot Token + App Token |
| Discord | `channels.discord` | discord.js 库 |
| Google Chat | `channels.googlechat` | Chat API |
| Signal | `channels.signal` | signal-cli |
| BlueBubbles | `channels.bluebubbles` | 推荐的 iMessage 集成 |
| iMessage | `channels.imessage` | 旧版 macOS-only |
| MS Teams | `channels.msteams` | Bot Framework extension |
| Matrix | `channels.matrix` | Extension |
| Zalo | `channels.zalo` | Extension |
| WebChat | — | 使用 Gateway WebSocket |

---

## 十、高级功能

### 10.1 Heartbeat（心跳）

Agent 周期性执行检查任务，通过 `HEARTBEAT.md` 定义检查清单。

**适用场景**：
- 批量检查（邮件 + 日历 + 通知）
- 需要对话上下文
- 时间精度要求不高（每 ~30 分钟）

### 10.2 Cron 任务

精确定时和独立任务。

**适用场景**：
- 精确时间触发
- 需要隔离会话
- 需要不同模型/思考级别
- 一次性提醒

### 10.3 Webhooks

外部触发器，接收 HTTP 请求并路由到 Agent。

### 10.4 Agent to Agent（多 Agent 协作）

- `sessions_list` — 发现活跃会话
- `sessions_history` — 获取会话日志
- `sessions_send` — 向另一个会话发消息

### 10.5 Tailscale 远程访问

```json5
{
  gateway: {
    tailscale: {
      mode: "serve",    // off | serve | funnel
      resetOnExit: false,
    },
  },
}
```

- `serve`: 仅 tailnet 内 HTTPS
- `funnel`: 公网 HTTPS（需要密码认证）

---

## 十一、故障排查

### 11.1 常用诊断命令

```bash
openclaw doctor          # 全面诊断
openclaw doctor --fix    # 自动修复
openclaw logs            # 查看日志
openclaw health          # 健康检查
openclaw status --all    # 完整状态
```

### 11.2 常见问题

| 问题 | 解决方案 |
|------|----------|
| Gateway 无法启动 | 运行 `openclaw doctor` 检查配置错误 |
| Skills 不加载 | 检查 `requires.bins` 依赖是否在 PATH 中 |
| 通道连接失败 | 检查 Token/认证配置，参考各通道文档 |
| 消息不响应 | 检查 `dmPolicy` 和 `allowFrom` 配置 |
| 配置验证失败 | 只有诊断命令可用，运行 `openclaw doctor --fix` |

---

## 十二、参考链接

### 官方文档
- [文档首页](https://docs.openclaw.ai)
- [配置参考](https://docs.openclaw.ai/gateway/configuration)
- [技能文档](https://docs.openclaw.ai/tools/skills)
- [安全指南](https://docs.openclaw.ai/gateway/security)
- [架构概览](https://docs.openclaw.ai/concepts/architecture)

### 平台指南
- [Windows (WSL2)](https://docs.openclaw.ai/platforms/windows)
- [Linux](https://docs.openclaw.ai/platforms/linux)
- [macOS](https://docs.openclaw.ai/platforms/macos)
- [iOS](https://docs.openclaw.ai/platforms/ios)
- [Android](https://docs.openclaw.ai/platforms/android)

### 通道文档
- [WhatsApp](https://docs.openclaw.ai/channels/whatsapp)
- [Telegram](https://docs.openclaw.ai/channels/telegram)
- [Discord](https://docs.openclaw.ai/channels/discord)
- [Slack](https://docs.openclaw.ai/channels/slack)

### 社区
- [GitHub](https://github.com/openclaw/openclaw)
- [Discord 社区](https://discord.gg/clawd)
- [ClawHub Skills 市场](https://clawhub.com)
- [DeepWiki](https://deepwiki.com/openclaw/openclaw)

# 飞书(Feishu/Lark) 通道配置指南

> 本文档指导你将 OpenClaw 连接到飞书，实现通过飞书 Bot 与 AI 助手交互。

---

## 前置条件

- OpenClaw Gateway 已安装并运行
- 你有飞书企业管理员权限（或可申请企业自建应用）

---

## 第一步：安装飞书插件

```bash
openclaw plugins install @openclaw/feishu
```

> 源码构建用户也可使用本地路径安装：
> ```bash
> openclaw plugins install ./extensions/feishu
> ```

---

## 第二步：创建飞书应用

### 1. 打开飞书开放平台

- **飞书（中国大陆）**: https://open.feishu.cn/app
- **Lark（国际版）**: https://open.larksuite.com/app

> 如果使用 Lark 国际版，需要在配置中添加 `domain: "lark"`

### 2. 创建企业自建应用

1. 点击 **创建企业自建应用**
2. 填写应用名称（如 "Clawd AI 助手"）和描述
3. 选择应用图标

### 3. 获取凭证

在应用的 **凭证与基础信息** 页面获取：
- **App ID**（格式：`cli_xxx`）
- **App Secret**

> **重要**：App Secret 必须安全保存，不要泄露！

### 4. 配置权限

在 **权限管理** 中开启以下权限：

```json
{
  "scopes": {
    "tenant": [
      "aily:file:read",
      "aily:file:write",
      "application:application.app_message_stats.overview:readonly",
      "application:application:self_manage",
      "application:bot.menu:write",
      "contact:user.employee_id:readonly",
      "corehr:file:download",
      "event:ip_list",
      "im:chat.access_event.bot_p2p_chat:read",
      "im:chat.members:bot_access",
      "im:message",
      "im:message.group_at_msg:readonly",
      "im:message.p2p_msg:readonly",
      "im:message:readonly",
      "im:message:send_as_bot",
      "im:resource"
    ],
    "user": [
      "aily:file:read",
      "aily:file:write",
      "im:chat.access_event.bot_p2p_chat:read"
    ]
  }
}
```

### 5. 启用机器人能力

1. 在 **添加应用能力** 中添加 **机器人**
2. 设置机器人名称

### 6. 配置事件订阅

1. 选择 **使用长连接接收事件（WebSocket）**
2. 添加事件：`im.message.receive_v1`

### 7. 发布应用

1. 在 **版本管理与发布** 中创建版本
2. 提交审核并发布
3. 等待管理员审批（企业应用通常自动审批）

---

## 第三步：配置 OpenClaw

### 方式一：使用配置向导（推荐）

```bash
openclaw channels add
```

按提示输入 App ID 和 App Secret 即可。

### 方式二：手动编辑配置文件

编辑 `~/.openclaw/openclaw.json`（或 `moltbot.json`），添加：

```json5
{
  channels: {
    feishu: {
      enabled: true,
      dmPolicy: "pairing",        // pairing=配对码 | open=开放 | allowlist=白名单
      // domain: "lark",           // 使用 Lark 国际版时取消注释
      accounts: {
        main: {
          appId: "cli_xxx",        // 替换为你的 App ID
          appSecret: "xxx",        // 替换为你的 App Secret
          botName: "Clawd AI",     // 替换为你的 Bot 名称
        },
      },
    },
  },
}
```

### 方式三：环境变量配置

```bash
export FEISHU_APP_ID="cli_xxx"
export FEISHU_APP_SECRET="xxx"
```

---

## 第四步：启动和测试

### 1. 启动 Gateway

```bash
openclaw gateway
# 或如果已经作为服务运行
openclaw gateway status
```

### 2. 发送测试消息

在飞书中搜索你的机器人名称，发送一条消息。

### 3. 配对确认

如果 `dmPolicy` 设为 `pairing`（默认），首次对话时需要审批配对码：

```bash
openclaw pairing list
openclaw pairing approve <pairing-code>
```

---

## 高级配置

### 群聊配置

```json5
{
  channels: {
    feishu: {
      groupPolicy: "open",          // 允许所有群
      groups: {
        "<chat_id>": {
          requireMention: true,      // 群聊中需要 @机器人 才响应
          enabled: true,
        },
      },
    },
  },
}
```

### 消息限制

```json5
{
  channels: {
    feishu: {
      textChunkLimit: 2000,          // 文本消息长度限制
      mediaMaxMb: 30,                // 媒体文件大小上限 (MB)
      streaming: true,               // 启用流式响应
      blockStreaming: true,           // 启用代码块流式
    },
  },
}
```

### 多账号配置

```json5
{
  channels: {
    feishu: {
      accounts: {
        main: { appId: "cli_aaa", appSecret: "secret_a", botName: "主助手" },
        dev: { appId: "cli_bbb", appSecret: "secret_b", botName: "开发助手" },
      },
    },
  },
}
```

---

## 故障排查

| 问题 | 解决方案 |
|------|----------|
| 群聊中不回复 | 确认已添加 `im.message.group_at_msg:readonly` 权限 |
| 不接收消息 | 检查事件订阅是否添加了 `im.message.receive_v1`，且使用了长连接模式 |
| App Secret 泄露 | 立即在开放平台重置 Secret，并更新 OpenClaw 配置 |
| 消息发送失败 | 确认 `im:message:send_as_bot` 权限已开启 |

---

## 相关 Skills

以下 Skills 可增强飞书体验：

- **feishu-card**: 发送富文本交互卡片到飞书用户或群组
- **feishu-memory-recall**: 从记忆中恢复飞书相关上下文

安装方式：
```bash
npx clawhub@latest install feishu-card --workdir "D:\home\node\clawd"
npx clawhub@latest install feishu-memory-recall --workdir "D:\home\node\clawd"
```

---

## 参考链接

- [OpenClaw 飞书通道官方文档](https://docs.openclaw.ai/channels/feishu)
- [飞书开放平台](https://open.feishu.cn/app)
- [Lark 开放平台](https://open.larksuite.com/app)

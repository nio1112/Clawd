# TOOLS.md - Environment Notes

*这里记录你的具体运行环境信息。Skills 定义了工具如何工作，这个文件存储环境特定配置。*

## 系统环境

- **操作系统**: Windows 10 (运行原生 Node.js，非 WSL)
- **Shell**: PowerShell (pwsh)
- **Node.js**: 已安装
- **包管理器**: npm
- **编辑器**: VS Code

## 项目路径

- **工作区根目录**: `D:\home\node\clawd`
- **OpenClaw 配置**: `C:\Users\nio.l.SJFOOD\.openclaw\`
- **主配置文件**: `C:\Users\nio.l.SJFOOD\.openclaw\moltbot.json`

## 网络访问

- **Gateway URL**: `http://127.0.0.1:18789`
- **WebChat**: `http://127.0.0.1:18789/chat`

## 注意事项

- Windows 下 PowerShell 命令语法与 bash 不同，注意适配
- 路径使用反斜杠 `\` 或正斜杠 `/` 均可
- 环境变量使用 `$env:VAR_NAME` 格式

## 已安装的 Skills

| Skill | 功能 |
|-------|------|
| `summarize` | 文本/网页摘要 |
| `weather` | 天气查询 |
| `blogwatcher` | 博客/RSS 监控 |
| `skill-creator` | 技能创建向导 |
| `git-essentials` | Git 常用命令 |
| `conventional-commits` | 规范化提交信息 |
| `deepwiki` | GitHub 仓库文档查询 |
| `feishu-card` | 飞书富文本交互卡片 |
| `simple_example` | 示例模板 |

> 更多推荐 Skills 可通过 `.\scripts\install-skills.ps1` 批量安装

## SSH Hosts / Remote Machines

*(如有远程机器，在此记录)*

## Camera / Audio / TTS

*(如有摄像头、音频或 TTS 设备，在此记录)*

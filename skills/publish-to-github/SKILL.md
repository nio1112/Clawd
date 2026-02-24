---
name: publish-to-github
description: 将本地项目发布或推送更新到 GitHub 仓库。支持自动创建仓库、非交互模式、凭证自动获取。修复原版 goto 语法错误，完全兼容 PowerShell。
author: NIO.L & Antigravity Agent
version: 2.0.0
---

# Publish to GitHub Skill

将本地项目自动发布到 GitHub，一条命令完成「创建仓库 → 提交代码 → 推送」全过程。

## 功能

### 首次发布（新项目）
1. 检查/初始化 Git 仓库
2. 检查/创建 `.gitignore`
3. 暂存并提交所有文件
4. 自动从 Git 凭证存储获取 GitHub Token
5. 通过 GitHub API 创建远程仓库（不依赖 `gh` CLI）
6. 设置 remote 并推送代码
7. 可选：设置仓库 Topics 标签

### 后续更新（已有仓库）
1. 暂存并提交修改
2. 自动推送到已关联的远程仓库

## 前置条件

- **Git**: 已安装（`git --version`）
- **PowerShell**: Windows/macOS/Linux 的 PowerShell 5.1+
- **GitHub 凭证**: Git credential store 中已存储 GitHub Token
  - 如果你之前用 `git push` 推过 GitHub，凭证通常已自动保存
  - 或手动配置: `git config --global credential.helper wincred`

## 使用方法

### AI Agent 模式（非交互，推荐）

```powershell
# 首次发布新项目
powershell -ExecutionPolicy Bypass -File ".\skills\publish-to-github\scripts\publish.ps1" `
    -RepoName "MyProject" `
    -Description "我的项目描述" `
    -CommitMessage "feat: initial commit" `
    -Topics "ai,automation,tools" `
    -Public

# 推送更新（已有仓库）
powershell -ExecutionPolicy Bypass -File ".\skills\publish-to-github\scripts\publish.ps1" `
    -CommitMessage "fix: 修复某个问题"

# 强制推送（解决冲突）
powershell -ExecutionPolicy Bypass -File ".\skills\publish-to-github\scripts\publish.ps1" `
    -CommitMessage "refactor: 重构代码" `
    -ForcePush
```

### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `-RepoName` | string | 当前目录名 | GitHub 仓库名称 |
| `-Description` | string | 空 | 仓库描述 |
| `-CommitMessage` | string | "Update via publish skill" | 提交信息 |
| `-Topics` | string | 空 | 逗号分隔的 topics |
| `-Public` | switch | false | 仓库是否公开 |
| `-ForcePush` | switch | false | 是否强制推送 |
| `-Branch` | string | "main" | 推送的分支名 |
| `-RemoteUrl` | string | 空 | 手动指定 remote URL（跳过 API 创建） |

## 目录结构

```text
publish-to-github/
├── SKILL.md              # 本说明文件
└── scripts/
    └── publish.ps1       # 自动化脚本 (v2.0)
```

## v2.0 更新日志

相比 v1.0 的改进：
- **修复**: PowerShell 不支持的 `goto`/`:label` 语法（CMD 语法）
- **新增**: 非交互模式，所有参数通过命令行传入，AI Agent 可直接调用
- **新增**: 自动通过 GitHub API 创建仓库（不依赖 `gh` CLI）
- **新增**: 自动从 Git credential store 获取 Token
- **新增**: 支持仓库 Topics 设置
- **新增**: 支持"首次发布"和"后续更新"两种场景
- **改进**: 完善的错误处理和彩色日志输出
- **改进**: 支持 `-ForcePush` 参数解决推送冲突

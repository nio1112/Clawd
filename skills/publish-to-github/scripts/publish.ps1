<#
.SYNOPSIS
    将本地项目发布或推送更新到 GitHub 仓库。
    支持自动创建仓库、非交互模式、凭证自动获取。
    v2.0 — 修复 goto 语法，完全兼容 PowerShell。

.DESCRIPTION
    此脚本完成以下工作：
    1. 检查/初始化 Git 仓库
    2. 检查 .gitignore
    3. 暂存并提交文件
    4. 自动获取 GitHub 凭证（从 git credential store）
    5. 通过 GitHub API 创建远程仓库（如果需要）
    6. 设置 remote 并推送代码
    7. 可选设置仓库 Topics

.EXAMPLE
    # 首次发布
    .\publish.ps1 -RepoName "MyProject" -Description "项目描述" -Public -CommitMessage "feat: initial commit"

.EXAMPLE
    # 推送更新
    .\publish.ps1 -CommitMessage "fix: 修复 bug"

.EXAMPLE
    # 手动指定 remote URL
    .\publish.ps1 -RemoteUrl "https://github.com/user/repo.git" -CommitMessage "feat: init"
#>

param(
    [string]$RepoName = "",
    [string]$Description = "",
    [string]$CommitMessage = "Update via publish skill",
    [string]$Topics = "",
    [switch]$Public,
    [switch]$ForcePush,
    [string]$Branch = "main",
    [string]$RemoteUrl = ""
)

$ErrorActionPreference = "Stop"

# ============================================================
# 工具函数
# ============================================================

function Write-Step {
    param([string]$num, [string]$msg)
    Write-Host ""
    Write-Host "[$num] $msg" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor DarkCyan
}

function Write-OK {
    param([string]$msg)
    Write-Host "  [OK] $msg" -ForegroundColor Green
}

function Write-Warn {
    param([string]$msg)
    Write-Host "  [WARN] $msg" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$msg)
    Write-Host "  [ERROR] $msg" -ForegroundColor Red
}

function Write-Info {
    param([string]$msg)
    Write-Host "  [INFO] $msg" -ForegroundColor Gray
}

# ============================================================
# 获取 GitHub 凭证（从 git credential store）
# ============================================================

function Get-GitHubCredential {
    <#
    .SYNOPSIS
        通过 git credential fill 从系统凭证存储中获取 GitHub Token。
        使用 System.Diagnostics.Process 精确控制 stdin，
        避免 PowerShell 管道在 Windows 下的多行 stdin 兼容性问题。
    #>
    try {
        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo.FileName = "git"
        $proc.StartInfo.Arguments = "credential fill"
        $proc.StartInfo.UseShellExecute = $false
        $proc.StartInfo.RedirectStandardInput = $true
        $proc.StartInfo.RedirectStandardOutput = $true
        $proc.StartInfo.RedirectStandardError = $true
        $proc.StartInfo.CreateNoWindow = $true
        $proc.Start() | Out-Null

        # 向 stdin 写入协议和主机信息
        $proc.StandardInput.WriteLine("protocol=https")
        $proc.StandardInput.WriteLine("host=github.com")
        $proc.StandardInput.WriteLine("")
        $proc.StandardInput.Close()

        $output = $proc.StandardOutput.ReadToEnd()
        $proc.WaitForExit(10000) # 最多等待 10 秒

        # 解析输出
        $lines = $output -split "`n"
        $username = ""
        $token = ""

        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ($trimmed -match "^username=(.+)$") {
                $username = $Matches[1].Trim()
            }
            if ($trimmed -match "^password=(.+)$") {
                $token = $Matches[1].Trim()
            }
        }

        if ([string]::IsNullOrEmpty($token)) {
            return $null
        }

        return @{
            Username = $username
            Token    = $token
        }
    }
    catch {
        Write-Warn "获取 Git 凭证失败: $($_.Exception.Message)"
        return $null
    }
}

# ============================================================
# 通过 GitHub API 创建仓库
# ============================================================

function New-GitHubRepository {
    param(
        [string]$Token,
        [string]$Name,
        [string]$Description,
        [bool]$IsPublic
    )

    $headers = @{
        "Authorization" = "token $Token"
        "Accept"        = "application/vnd.github.v3+json"
        "User-Agent"    = "publish-to-github-skill/2.0"
    }

    $body = @{
        name         = $Name
        description  = $Description
        private      = -not $IsPublic
        auto_init    = $false
        has_issues   = $true
        has_wiki     = $false
        has_projects = $false
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" `
            -Method POST -Headers $headers -Body $body -ContentType "application/json"
        return @{
            Success  = $true
            Url      = $response.html_url
            CloneUrl = $response.clone_url
            Message  = "仓库创建成功"
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 422) {
            # 仓库已存在，获取现有仓库信息
            try {
                # 从 API 获取用户名
                $userInfo = Invoke-RestMethod -Uri "https://api.github.com/user" `
                    -Method GET -Headers $headers
                $owner = $userInfo.login

                $existing = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$Name" `
                    -Method GET -Headers $headers
                return @{
                    Success  = $true
                    Url      = $existing.html_url
                    CloneUrl = $existing.clone_url
                    Message  = "仓库已存在，将使用现有仓库"
                }
            }
            catch {
                return @{
                    Success = $false
                    Message = "仓库可能已存在但无法获取信息: $($_.Exception.Message)"
                }
            }
        }
        else {
            return @{
                Success = $false
                Message = "创建仓库失败 (HTTP $statusCode): $($_.Exception.Message)"
            }
        }
    }
}

# ============================================================
# 设置仓库 Topics
# ============================================================

function Set-GitHubTopics {
    param(
        [string]$Token,
        [string]$Owner,
        [string]$Repo,
        [string[]]$TopicsList
    )

    $headers = @{
        "Authorization" = "token $Token"
        "Accept"        = "application/vnd.github.mercy-preview+json"
    }

    $body = @{
        names = $TopicsList
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/topics" `
            -Method PUT -Headers $headers -Body $body -ContentType "application/json" | Out-Null
        return $true
    }
    catch {
        Write-Warn "设置 Topics 失败: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================
# 主流程
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Publish to GitHub  v2.0" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# --- Step 1: 检查/初始化 Git ---
Write-Step "1/6" "检查 Git 状态"

if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Err "Git 未安装，请先安装 Git。"
    exit 1
}

if (-not (Test-Path ".git")) {
    Write-Info "初始化新的 Git 仓库..."
    git init | Out-Null
    Write-OK "Git 仓库已初始化"
}
else {
    Write-OK "Git 仓库已存在"
}

# --- Step 2: 检查 .gitignore ---
Write-Step "2/6" "检查 .gitignore"

if (-not (Test-Path ".gitignore")) {
    Write-Warn "未发现 .gitignore 文件"
    Write-Info "创建默认 .gitignore..."
    @(
        "# System files",
        ".DS_Store",
        "Thumbs.db",
        "desktop.ini",
        "",
        "# Node.js",
        "node_modules/",
        "npm-debug.log*",
        "",
        "# IDE",
        ".vscode/settings.json",
        ".idea/",
        "",
        "# Temp",
        "*.tmp",
        "*.bak",
        "*.log"
    ) | Out-File -Encoding utf8 ".gitignore"
    Write-OK "已创建默认 .gitignore"
}
else {
    Write-OK ".gitignore 已存在"
}

# --- Step 3: 提交代码 ---
Write-Step "3/6" "提交代码"

git add --all 2>&1 | Out-Null
$status = git status --porcelain

if ($status) {
    $changedCount = ($status | Measure-Object).Count
    Write-Info "发现 $changedCount 个变更文件"
    git commit -m "$CommitMessage" 2>&1 | Out-Null
    Write-OK "代码已提交: $CommitMessage"
}
else {
    Write-Warn "没有新的变更需要提交（工作区干净）"
}

# --- Step 4: 配置远程仓库 ---
Write-Step "4/6" "配置远程仓库"

$hasOrigin = (git remote 2>&1) -contains "origin"
$needsCreateRepo = $false
$cloneUrl = ""

if ($hasOrigin) {
    $currentUrl = git remote get-url origin 2>&1
    Write-OK "Remote 'origin' 已配置: $currentUrl"
    $cloneUrl = $currentUrl
}
else {
    if (-not [string]::IsNullOrWhiteSpace($RemoteUrl)) {
        # 用户手动指定了 URL
        Write-Info "使用指定的 Remote URL..."
        git remote add origin $RemoteUrl
        Write-OK "Remote 'origin' 已添加: $RemoteUrl"
        $cloneUrl = $RemoteUrl
    }
    else {
        # 需要通过 API 创建仓库
        $needsCreateRepo = $true
    }
}

# --- Step 5: 创建仓库（如需要）---
Write-Step "5/6" "GitHub 仓库管理"

$credential = $null

if ($needsCreateRepo) {
    # 获取 GitHub 凭证
    Write-Info "从 Git credential store 获取 GitHub 凭证..."
    $credential = Get-GitHubCredential

    if ($null -eq $credential) {
        Write-Err "无法获取 GitHub 凭证。请确保你之前已通过 git push 认证过 GitHub。"
        Write-Info "或手动指定 -RemoteUrl 参数。"
        exit 1
    }

    Write-OK "凭证获取成功 (用户: $($credential.Username))"

    # 确定仓库名
    if ([string]::IsNullOrWhiteSpace($RepoName)) {
        $RepoName = Split-Path -Leaf (Get-Location)
    }

    Write-Info "创建 GitHub 仓库: $RepoName ..."

    $repoResult = New-GitHubRepository `
        -Token $credential.Token `
        -Name $RepoName `
        -Description $Description `
        -IsPublic $Public.IsPresent

    if ($repoResult.Success) {
        Write-OK "$($repoResult.Message): $($repoResult.Url)"
        $cloneUrl = $repoResult.CloneUrl
        git remote add origin $cloneUrl
        Write-OK "Remote 'origin' 已添加"
    }
    else {
        Write-Err $repoResult.Message
        exit 1
    }
}
else {
    Write-OK "仓库已配置，跳过创建"
}

# 设置 Topics（如果指定了）
if (-not [string]::IsNullOrWhiteSpace($Topics) -and $null -ne $credential) {
    $topicsList = $Topics -split "," | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -ne "" }
    if ($topicsList.Count -gt 0) {
        # 从 clone URL 解析 owner
        if ($cloneUrl -match "github\.com[/:]([^/]+)/([^/.]+)") {
            $owner = $Matches[1]
            $repo = $Matches[2]
            Write-Info "设置 Topics: $($topicsList -join ', ')..."
            $topicsResult = Set-GitHubTopics -Token $credential.Token -Owner $owner -Repo $repo -TopicsList $topicsList
            if ($topicsResult) {
                Write-OK "Topics 已设置"
            }
        }
    }
}
elseif (-not [string]::IsNullOrWhiteSpace($Topics) -and $null -eq $credential) {
    # 有 topics 但没凭证（已有 remote 的情况），需要获取凭证
    $credential = Get-GitHubCredential
    if ($null -ne $credential) {
        $topicsList = $Topics -split "," | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -ne "" }
        if ($topicsList.Count -gt 0 -and $cloneUrl -match "github\.com[/:]([^/]+)/([^/.]+)") {
            $owner = $Matches[1]
            $repo = $Matches[2]
            Write-Info "设置 Topics: $($topicsList -join ', ')..."
            Set-GitHubTopics -Token $credential.Token -Owner $owner -Repo $repo -TopicsList $topicsList | Out-Null
            Write-OK "Topics 已设置"
        }
    }
}

# --- Step 6: 推送 ---
Write-Step "6/6" "推送代码"

# 确保分支名正确
git branch -M $Branch 2>&1 | Out-Null

if ($ForcePush) {
    Write-Warn "强制推送模式..."
    $pushResult = git push -f -u origin $Branch 2>&1
}
else {
    $pushResult = git push -u origin $Branch 2>&1
}

$pushExitCode = $LASTEXITCODE

if ($pushExitCode -eq 0) {
    Write-OK "代码推送成功!"
}
else {
    # 检查是否是因为远程有内容的问题
    $pushStr = $pushResult -join " "
    if ($pushStr -match "rejected.*non-fast-forward" -or $pushStr -match "failed to push") {
        Write-Warn "推送被拒绝（远程有不同的提交历史）"
        Write-Info "尝试使用 -ForcePush 参数强制推送（仅限新仓库）"
        Write-Info "或先执行 git pull --rebase origin $Branch 后再推送"
    }
    else {
        Write-Err "推送失败: $pushStr"
    }
    exit 1
}

# --- 完成 ---
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  发布成功!" -ForegroundColor Green
if ($cloneUrl -match "github\.com[/:]([^/]+)/([^/.]+)") {
    $repoUrl = "https://github.com/$($Matches[1])/$($Matches[2])"
    Write-Host "  $repoUrl" -ForegroundColor White
}
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

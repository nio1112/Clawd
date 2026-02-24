# OpenClaw Skills 批量安装脚本
# 使用方法: 在项目根目录运行此脚本
# PowerShell:  .\scripts\install-skills.ps1

param(
    [string]$WorkDir = (Get-Location).Path,
    [int]$DelaySeconds = 10
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  OpenClaw Skills 批量安装脚本" -ForegroundColor Cyan
Write-Host "  工作目录: $WorkDir" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 推荐安装的 Skills 列表
$skills = @(
    # === 内置热门 Skills ===
    "summarize",              # 文本/网页摘要
    "weather",                # 天气查询
    "blogwatcher",            # 博客/RSS 监控
    "skill-creator",          # 技能创建向导

    # === Git & 开发 ===
    "git-essentials",         # Git 常用命令
    "conventional-commits",   # 规范化提交信息
    "deepwiki",               # GitHub 仓库文档查询

    # === 搜索 & 研究 ===
    "baidu-search",           # 百度搜索
    "bing-search",            # Bing 搜索
    "arxiv-watcher",          # ArXiv 论文搜索

    # === 生产力 ===
    "ai-daily-briefing",      # 每日简报
    "agent-memory",           # 持久化记忆系统

    # === 文档 ===
    "docx",                   # Word 文档生成和编辑
    "image-ocr",              # 图片 OCR 文字识别

    # === 飞书相关 ===
    "feishu-card",            # 飞书富文本卡片
    "feishu-memory-recall"    # 飞书记忆恢复
)

$installed = @()
$failed = @()

foreach ($skill in $skills) {
    Write-Host "`n--- 安装: $skill ---" -ForegroundColor Yellow

    try {
        $result = npx clawhub@latest install $skill --workdir $WorkDir --force 2>&1
        $resultStr = $result -join "`n"

        if ($resultStr -match "OK\. Installed") {
            Write-Host "  ✅ 安装成功" -ForegroundColor Green
            $installed += $skill
        }
        elseif ($resultStr -match "Rate limit") {
            Write-Host "  ⏳ 触发速率限制，等待 ${DelaySeconds} 秒后重试..." -ForegroundColor Yellow
            Start-Sleep -Seconds $DelaySeconds

            $result = npx clawhub@latest install $skill --workdir $WorkDir --force 2>&1
            $resultStr = $result -join "`n"

            if ($resultStr -match "OK\. Installed") {
                Write-Host "  ✅ 重试安装成功" -ForegroundColor Green
                $installed += $skill
            } else {
                Write-Host "  ❌ 重试后仍失败: $resultStr" -ForegroundColor Red
                $failed += $skill
            }
        }
        elseif ($resultStr -match "already exists") {
            Write-Host "  ℹ️ 已存在，跳过" -ForegroundColor Cyan
            $installed += $skill
        }
        else {
            Write-Host "  ❌ 安装失败: $resultStr" -ForegroundColor Red
            $failed += $skill
        }
    }
    catch {
        Write-Host "  ❌ 异常: $_" -ForegroundColor Red
        $failed += $skill
    }

    # 每次安装间隔 3 秒，避免触发速率限制
    Start-Sleep -Seconds 3
}

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  安装完成！" -ForegroundColor Cyan
Write-Host "  ✅ 成功: $($installed.Count) 个" -ForegroundColor Green
if ($failed.Count -gt 0) {
    Write-Host "  ❌ 失败: $($failed.Count) 个" -ForegroundColor Red
    Write-Host "  失败列表: $($failed -join ', ')" -ForegroundColor Red
    Write-Host "`n  提示: 失败的 skill 可能是因为速率限制。" -ForegroundColor Yellow
    Write-Host "  请等待几分钟后再运行: " -ForegroundColor Yellow
    foreach ($f in $failed) {
        Write-Host "    npx clawhub@latest install $f --workdir `"$WorkDir`" --force" -ForegroundColor Gray
    }
}
Write-Host "================================================" -ForegroundColor Cyan

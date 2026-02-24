$subreddits = @(
    "LocalLLaMA",
    "MachineLearning",
    "ChatGPT",
    "ClaudeAI",
    "Singularity"
)

foreach ($sub in $subreddits) {
    Write-Host "=== r/$sub ==="
    try {
        $response = Invoke-WebRequest -Uri "https://www.reddit.com/r/$sub/hot.json?limit=5" -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" -TimeoutSec 10
        $json = $response.Content | ConvertFrom-Json
        foreach ($post in $json.data.children) {
            $title = $post.data.title
            $score = $post.data.score
            $comments = $post.data.num_comments
            $url = $post.data.url
            $selftext = $post.data.selftext
            if ($selftext.Length -gt 200) {
                $selftext = $selftext.Substring(0, 200) + "..."
            }
            Write-Host "[$score pts] $title"
            Write-Host "  Comments: $comments | URL: $url"
            if ($selftext) {
                Write-Host "  $selftext"
            }
            Write-Host ""
        }
    } catch {
        Write-Host "Error: $_"
    }
    Write-Host ""
}

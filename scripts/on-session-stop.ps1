# Fired by Claude Code Stop hook at the end of each Claude turn.
# Extracts the conversation from the session transcript and pushes to GitHub.

$handoff_dir = "C:\Users\EricaGeorgis\Documents\claude-handoff"
$session_id   = $env:CLAUDE_SESSION_ID
$timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$date         = Get-Date -Format "yyyy-MM-dd"
$session_dir  = "$handoff_dir\sessions\$date"

if (-not (Test-Path $session_dir)) {
    New-Item -ItemType Directory -Path $session_dir -Force | Out-Null
}

# Find the transcript for this session across all projects
$transcript = Get-ChildItem "$env:USERPROFILE\.claude\projects" -Recurse -Filter "${session_id}.jsonl" -ErrorAction SilentlyContinue | Select-Object -First 1

$conv_file = "$session_dir\${session_id}_conversation.md"

if ($transcript -and (Test-Path $transcript.FullName)) {
    $lines = Get-Content $transcript.FullName -Encoding utf8 -ErrorAction SilentlyContinue
    $output = [System.Text.StringBuilder]::new()
    [void]$output.AppendLine("# Conversation Log")
    [void]$output.AppendLine("**Session:** $session_id")
    [void]$output.AppendLine("**Last updated:** $timestamp")
    [void]$output.AppendLine("")
    [void]$output.AppendLine("---")
    [void]$output.AppendLine("")

    foreach ($line in $lines) {
        if (-not $line.Trim()) { continue }
        try {
            $entry = $line | ConvertFrom-Json -ErrorAction Stop
            $role = $entry.message.role
            if (-not $role) { continue }

            $content = $entry.message.content
            if ($role -eq "user") {
                [void]$output.AppendLine("### User")
                if ($content -is [string]) {
                    [void]$output.AppendLine($content)
                } elseif ($content -is [array]) {
                    $text = ($content | Where-Object { $_.type -eq "text" } | ForEach-Object { $_.text }) -join "`n"
                    [void]$output.AppendLine($text)
                }
                [void]$output.AppendLine("")
            } elseif ($role -eq "assistant") {
                [void]$output.AppendLine("### Claude")
                if ($content -is [array]) {
                    $text = ($content | Where-Object { $_.type -eq "text" } | ForEach-Object { $_.text }) -join "`n"
                    if ($text) { [void]$output.AppendLine($text) }
                } elseif ($content -is [string]) {
                    [void]$output.AppendLine($content)
                }
                [void]$output.AppendLine("")
            }
        } catch {}
    }

    Set-Content $conv_file $output.ToString() -Encoding utf8
}

# Commit and push everything
Push-Location $handoff_dir
git add -A 2>&1 | Out-Null
$status = git status --porcelain 2>&1
if ($status) {
    git commit -m "Session update: $timestamp [$session_id]" 2>&1 | Out-Null
    git push 2>&1 | Out-Null
}
Pop-Location

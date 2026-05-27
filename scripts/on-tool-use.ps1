# Fired by Claude Code PostToolUse hook after Write/Edit/MultiEdit
# Logs the file change and commits it to the handoff repo.

$handoff_dir = "C:\Users\EricaGeorgis\Documents\claude-handoff"
$session_id   = $env:CLAUDE_SESSION_ID
$timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$date         = Get-Date -Format "yyyy-MM-dd"
$session_dir  = "$handoff_dir\sessions\$date"

# Parse tool info from stdin
$raw = [Console]::In.ReadToEnd()
try { $data = $raw | ConvertFrom-Json } catch { $data = $null }

$tool_name = if ($data) { $data.tool_name } else { "unknown" }
$file_path = if ($data) {
    $data.tool_input.file_path ?? $data.tool_input.path ?? "(no path)"
} else { "(no path)" }

# Ensure session directory exists
if (-not (Test-Path $session_dir)) {
    New-Item -ItemType Directory -Path $session_dir -Force | Out-Null
}

$log_file = "$session_dir\${session_id}_changes.md"

# Create file with header on first use
if (-not (Test-Path $log_file)) {
    $header = @"
# Changes — Session $session_id
**Date:** $date

## File Changes

"@
    Set-Content $log_file $header -Encoding utf8
}

# Append change entry
$entry = "- ``$timestamp`` | **$tool_name** | ``$file_path```r`n"
Add-Content $log_file $entry -Encoding utf8

# Commit to handoff repo
Push-Location $handoff_dir
git add "$log_file" 2>&1 | Out-Null
$msg = "[$timestamp] $tool_name => $file_path"
git diff --cached --quiet 2>&1
if ($LASTEXITCODE -ne 0) {
    git commit -m $msg 2>&1 | Out-Null
    git push 2>&1 | Out-Null
}
Pop-Location

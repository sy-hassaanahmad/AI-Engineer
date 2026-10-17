# Auto-sync Colab/Drive changes to GitHub
param (
    [string]$CommitMessage = ""
)

$ErrorActionPreference = "Continue"
$RepoDir = "F:\My Drive\Chronos  - Skill Leveling\AI Engineer"
$LogFile = Join-Path $RepoDir "sync.log"

Set-Location -LiteralPath $RepoDir

function Log-Message([string]$msg, [string]$color = "White") {
    $timeStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "[$timeStr] $msg"
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    Write-Host $msg -ForegroundColor $color
}

# Keep sync.log reasonably sized (max 200KB)
if (Test-Path $LogFile) {
    $fileInfo = Get-Item $LogFile
    if ($fileInfo.Length -gt 200KB) {
        Get-Content $LogFile -Tail 200 | Set-Content ($LogFile + ".tmp")
        Move-Item ($LogFile + ".tmp") $LogFile -Force
    }
}

Log-Message "=== AI Engineer -> GitHub Sync Triggered ===" "Cyan"

# Check git status
$status = git status --porcelain
if (-not $status) {
    Log-Message "No changes detected. Repository is already clean." "Green"
    exit 0
}

Log-Message "Changes detected:" "Yellow"
$status | ForEach-Object { Log-Message "   $_" "Gray" }

# Determine commit message if not provided
if (-not $CommitMessage) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm")
    $changedFiles = git status --short | ForEach-Object {
        $parts = $_.Trim().Split(" ", 2)
        if ($parts.Length -gt 1) { [System.IO.Path]::GetFileNameWithoutExtension($parts[1].Trim()) }
    } | Where-Object { $_ -ne "sync" -and $_ -ne "sync-to-github" } | Select-Object -Unique -First 3
    
    if ($changedFiles) {
        $fileSummary = ($changedFiles -join ", ")
        $CommitMessage = "Update $fileSummary ($timestamp)"
    } else {
        $CommitMessage = "Update Colab study notes ($timestamp)"
    }
}

Log-Message "Staging changes..." "Cyan"
git add -A

Log-Message "Committing with message: '$CommitMessage'..." "Cyan"
$commitOut = git commit -m $CommitMessage 2>&1
Log-Message "$commitOut" "Gray"

# Pull latest if any remote changes exist
Log-Message "Syncing with remote..." "Cyan"
$pullOut = git pull --rebase origin main 2>&1
Log-Message "$pullOut" "Gray"

Log-Message "Pushing to GitHub (origin main)..." "Cyan"
$pushOut = git push origin main 2>&1
if ($LASTEXITCODE -eq 0) {
    Log-Message "[SUCCESS] Successfully pushed all updates to GitHub!" "Green"
    Log-Message "GitHub activity graph updated for @sy-hassaanahmad." "Green"
} else {
    Log-Message "[ERROR] Push failed: $pushOut" "Red"
    exit 1
}

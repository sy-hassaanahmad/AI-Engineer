# Auto-sync Colab/Drive changes to GitHub
param (
    [string]$CommitMessage = ""
)

$ErrorActionPreference = "Stop"
$RepoDir = "F:\My Drive\Chronos  - Skill Leveling\AI Engineer"

Set-Location -LiteralPath $RepoDir

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  AI Engineer -> GitHub Sync Engine" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check git status
$status = git status --porcelain
if (-not $status) {
    Write-Host "[OK] No changes detected. Repository is already clean and up to date." -ForegroundColor Green
    exit 0
}

Write-Host "[i] Changes detected:" -ForegroundColor Yellow
$status | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }

# Determine commit message if not provided
if (-not $CommitMessage) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm")
    # Find modified or added files
    $changedFiles = git status --short | ForEach-Object {
        $parts = $_.Trim().Split(" ", 2)
        if ($parts.Length -gt 1) { [System.IO.Path]::GetFileNameWithoutExtension($parts[1].Trim()) }
    } | Select-Object -Unique -First 3
    
    if ($changedFiles) {
        $fileSummary = ($changedFiles -join ", ")
        $CommitMessage = "Update $fileSummary ($timestamp)"
    } else {
        $CommitMessage = "Update Colab study notes ($timestamp)"
    }
}

Write-Host "[i] Staging files..." -ForegroundColor Cyan
git add -A

Write-Host "[i] Committing with message: '$CommitMessage'..." -ForegroundColor Cyan
git commit -m $CommitMessage

Write-Host "[i] Pushing to GitHub (origin main)..." -ForegroundColor Cyan
try {
    git push origin main
    Write-Host "[SUCCESS] Successfully pushed all updates to GitHub!" -ForegroundColor Green
    Write-Host "[i] Your GitHub activity graph will reflect these commits." -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Push failed: $_" -ForegroundColor Red
    exit 1
}

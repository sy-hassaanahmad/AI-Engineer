# Auto-sync Colab/Drive changes to GitHub
param (
    [string]$CommitMessage = ""
)

$ErrorActionPreference = "SilentlyContinue"
$RepoDir = "F:\My Drive\Chronos  - Skill Leveling\AI Engineer"

# Pre-flight check: exit quietly if F: drive or repo directory is not mounted/open
if (-not (Test-Path -LiteralPath "F:\")) {
    exit 0
}

if (-not (Test-Path -LiteralPath $RepoDir)) {
    exit 0
}

$LogFile = Join-Path $RepoDir "sync.log"

function Log-Message([string]$msg, [string]$color = "White") {
    $timeStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "[$timeStr] $msg"
    try {
        Add-Content -LiteralPath $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    } catch {}
    Write-Host $msg -ForegroundColor $color
}

# Enter repository safely
try {
    Set-Location -LiteralPath $RepoDir -ErrorAction Stop
} catch {
    exit 0
}

# Keep sync.log reasonably sized (max 200KB)
try {
    if (Test-Path -LiteralPath $LogFile) {
        $fileInfo = Get-Item -LiteralPath $LogFile -ErrorAction SilentlyContinue
        if ($fileInfo -and $fileInfo.Length -gt 200KB) {
            Get-Content -LiteralPath $LogFile -Tail 200 | Set-Content -LiteralPath ($LogFile + ".tmp") -ErrorAction SilentlyContinue
            Move-Item -LiteralPath ($LogFile + ".tmp") -Destination $LogFile -Force -ErrorAction SilentlyContinue
        }
    }

    # Check git status
    $status = git status --porcelain 2>&1
    if (-not $status) {
        Log-Message "No changes detected. Repository is already clean." "Green"
        exit 0
    }

    Log-Message "=== AI Engineer -> GitHub Sync Triggered ===" "Cyan"
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
    git add -A 2>&1 | Out-Null

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
    }
} catch {
    exit 0
}

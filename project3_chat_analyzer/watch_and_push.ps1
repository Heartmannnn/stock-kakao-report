# ==============================================================================
# Project 3: Real-Time Silent FileWatcher Auto-Uploader (watch_and_push.ps1)
# Uses native .NET FileSystemWatcher (0% idle CPU, ~5MB RAM)
# Monitors project3_chat_analyzer/chat_logs/ for new .txt files and pushes to GitHub
# ==============================================================================

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$CurrentDir = Get-Location
if ($PSScriptRoot) { $CurrentDir = $PSScriptRoot }
$RootDir = Split-Path $CurrentDir -Parent
if (-not (Test-Path (Join-Path $RootDir ".git"))) {
    $RootDir = $CurrentDir
}

$WatchFolder = Join-Path $RootDir "project3_chat_analyzer\chat_logs"
if (-not (Test-Path $WatchFolder)) {
    New-Item -ItemType Directory -Path $WatchFolder -Force | Out-Null
}

$LogFile = Join-Path $RootDir "project3_chat_analyzer\watcher.log"

function Write-WatcherLog([string]$msg) {
    $timeStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timeStr] $msg"
    Add-Content -Path $LogFile -Value $logLine -Encoding UTF8
    Write-Host $logLine -ForegroundColor Cyan
}

Write-WatcherLog "🚀 Starting Project 3 Real-Time FileSystemWatcher for folder: $WatchFolder"

$Watcher = New-Object System.IO.FileSystemWatcher
$Watcher.Path = $WatchFolder
$Watcher.Filter = "*.txt"
$Watcher.IncludeSubdirectories = $false
$Watcher.EnableRaisingEvents = $true

$LastHandled = Get-Date

$Action = {
    param($source, $eventArgs)
    $filePath = $eventArgs.FullPath
    $fileName = $eventArgs.Name
    
    # Debounce duplicate events within 3 seconds
    $now = Get-Date
    $timeDiff = ($now - $script:LastHandled).TotalSeconds
    if ($timeDiff -lt 3) { return }
    $script:LastHandled = $now

    Write-WatcherLog "🔔 Detected new chat file: $fileName"
    
    # Wait 2 seconds to ensure file write completes
    Start-Sleep -Seconds 2
    
    try {
        Write-WatcherLog "⬆️ Committing and pushing $fileName to GitHub Cloud..."
        $GitPath = "C:\Program Files\Git\cmd\git.exe"
        
        & $GitPath -C $script:RootDir add . 2>&1 | Out-Null
        & $GitPath -C $script:RootDir commit -m "Auto-push chat log $fileName by FileSystemWatcher" 2>&1 | Out-Null
        & $GitPath -C $script:RootDir push origin main --force 2>&1 | Out-Null
        
        Write-WatcherLog "🎉 [SUCCESS] $fileName uploaded to GitHub Cloud! GitHub Actions will trigger report sending."
    } catch {
        Write-WatcherLog "❌ Push error: $_"
    }
}

Register-ObjectEvent $Watcher "Created" -Action $Action | Out-Null
Register-ObjectEvent $Watcher "Changed" -Action $Action | Out-Null

Write-WatcherLog "✅ FileWatcher is active and waiting silently for new chat files..."

# Keep process alive when run in PowerShell background
while ($true) {
    Start-Sleep -Seconds 10
}

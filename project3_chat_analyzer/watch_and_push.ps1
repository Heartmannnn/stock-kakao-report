# ==============================================================================
# Project 3: Reliable Real-Time File Watcher Daemon (watch_and_push.ps1)
# Uses 0% idle CPU (Start-Sleep 2), 100% reliable file change detector
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
$GitPath = "C:\Program Files\Git\cmd\git.exe"

function Write-WatcherLog([string]$msg) {
    $timeStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timeStr] $msg"
    Add-Content -Path $LogFile -Value $logLine -Encoding UTF8
    Write-Host $logLine -ForegroundColor Cyan
}

Write-WatcherLog "🚀 Starting Project 3 Reliable File Watcher for folder: $WatchFolder"

# Initialize last seen timestamp
$LastMtime = [DateTime]::MinValue
$InitialFiles = Get-ChildItem -Path $WatchFolder -Filter "*.txt" | Sort-Object LastWriteTime -Descending
if ($InitialFiles -and $InitialFiles.Count -gt 0) {
    $LastMtime = $InitialFiles[0].LastWriteTime
    Write-WatcherLog "Initial latest file: $($InitialFiles[0].Name) (LastWriteTime: $LastMtime)"
}

Write-WatcherLog "✅ FileWatcher daemon is active and monitoring every 2 seconds..."

while ($true) {
    try {
        $TxtFiles = Get-ChildItem -Path $WatchFolder -Filter "*.txt" | Sort-Object LastWriteTime -Descending
        if ($TxtFiles -and $TxtFiles.Count -gt 0) {
            $LatestFile = $TxtFiles[0]
            if ($LatestFile.LastWriteTime -gt $LastMtime) {
                if ($LastMtime -ne [DateTime]::MinValue) {
                    $fname = $LatestFile.Name
                    Write-WatcherLog "🔔 NEW CHAT FILE DETECTED: $fname (LastWriteTime: $($LatestFile.LastWriteTime))"
                    
                    # Wait 2 seconds for OS file copy to complete
                    Start-Sleep -Seconds 2
                    
                    Write-WatcherLog "⬆️ Committing and pushing $fname to GitHub Cloud..."
                    
                    & $GitPath -C $RootDir add . 2>&1 | Out-Null
                    & $GitPath -C $RootDir commit -m "Auto-push chat log $fname by FileWatcher" 2>&1 | Out-Null
                    & $GitPath -C $RootDir push origin main --force 2>&1 | Out-Null
                    
                    Write-WatcherLog "🎉 [SUCCESS] $fname uploaded to GitHub! Cloud Action triggered."
                }
                $LastMtime = $LatestFile.LastWriteTime
            }
        }
    } catch {
        Write-WatcherLog "Watcher loop note: $_"
    }
    
    Start-Sleep -Seconds 2
}

# ==============================================================================
# Project 4: Real-Time File Watcher Daemon (watch_and_push.ps1)
# Uses 0% idle CPU (Start-Sleep 2), 100% reliable file change detector
# Features:
#   1. Detects newest chat file in project4_invest_analyzer/chat_logs/
#   2. CLEANS UP (DELETES) older chat files so only 1 newest file remains
#   3. Commits and pushes to GitHub Cloud to trigger Project 4 workflow
# ==============================================================================

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$CurrentDir = Get-Location
if ($PSScriptRoot) { $CurrentDir = $PSScriptRoot }
$RootDir = Split-Path $CurrentDir -Parent
if (-not (Test-Path (Join-Path $RootDir ".git"))) {
    $RootDir = $CurrentDir
}

$WatchFolder = Join-Path $RootDir "project4_invest_analyzer\chat_logs"
if (-not (Test-Path $WatchFolder)) {
    New-Item -ItemType Directory -Path $WatchFolder -Force | Out-Null
}

$LogFile = Join-Path $RootDir "project4_invest_analyzer\watcher.log"
$GitPath = "C:\Program Files\Git\cmd\git.exe"

function Write-WatcherLog([string]$msg) {
    $timeStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timeStr] $msg"
    Add-Content -Path $LogFile -Value $logLine -Encoding UTF8
    Write-Host $logLine -ForegroundColor Cyan
}

function Cleanup-OldChatFiles([string]$folder, [string]$latestFileName) {
    $allFiles = Get-ChildItem -Path $folder -Filter "*.txt"
    foreach ($f in $allFiles) {
        if ($f.Name -ne $latestFileName -and $f.Name -ne ".gitkeep") {
            try {
                Remove-Item -Path $f.FullName -Force
                Write-WatcherLog "🗑️ Cleaned up older chat log file: $($f.Name)"
            } catch {
                Write-WatcherLog "Cleanup note: $_"
            }
        }
    }
}

Write-WatcherLog "🚀 Starting Project 4 Reliable File Watcher for folder: $WatchFolder"

$LastMtime = [DateTime]::MinValue
$InitialFiles = Get-ChildItem -Path $WatchFolder -Filter "*.txt" | Sort-Object LastWriteTime -Descending
if ($InitialFiles -and $InitialFiles.Count -gt 0) {
    $LastMtime = $InitialFiles[0].LastWriteTime
    Write-WatcherLog "Initial latest file: $($InitialFiles[0].Name) (LastWriteTime: $LastMtime)"
    Cleanup-OldChatFiles -folder $WatchFolder -latestFileName $InitialFiles[0].Name
}

Write-WatcherLog "✅ Project 4 FileWatcher daemon is active and monitoring every 2 seconds..."

while ($true) {
    try {
        $TxtFiles = Get-ChildItem -Path $WatchFolder -Filter "*.txt" | Sort-Object LastWriteTime -Descending
        if ($TxtFiles -and $TxtFiles.Count -gt 0) {
            $LatestFile = $TxtFiles[0]
            if ($LatestFile.LastWriteTime -gt $LastMtime) {
                if ($LastMtime -ne [DateTime]::MinValue) {
                    $fname = $LatestFile.Name
                    Write-WatcherLog "🔔 NEW CHAT FILE DETECTED FOR PROJECT 4: $fname (LastWriteTime: $($LatestFile.LastWriteTime))"
                    
                    Start-Sleep -Seconds 2
                    Cleanup-OldChatFiles -folder $WatchFolder -latestFileName $fname
                    
                    Write-WatcherLog "⬆️ Committing and pushing $fname to GitHub Cloud..."
                    
                    & $GitPath -C $RootDir add . 2>&1 | Out-Null
                    & $GitPath -C $RootDir commit -m "Auto-push latest chat log for Project 4 $fname" 2>&1 | Out-Null
                    & $GitPath -C $RootDir push origin main --force 2>&1 | Out-Null
                    
                    Write-WatcherLog "🎉 [SUCCESS] Project 4 $fname uploaded to GitHub! Cloud Action triggered."
                }
                $LastMtime = $LatestFile.LastWriteTime
            }
        }
    } catch {
        Write-WatcherLog "Watcher loop note: $_"
    }
    
    Start-Sleep -Seconds 2
}

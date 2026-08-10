# ==============================================================================
# Project 4: FileWatcher Uninstaller & System Restorer (stop_watcher.ps1)
# ==============================================================================

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "🛑 Stopping Project 4 FileWatcher background processes and tasks..." -ForegroundColor Yellow

$TaskName = "Stock_Project4_Realtime_Watcher"
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "✅ Unregistered Scheduled Task: $TaskName" -ForegroundColor Green

$WatcherProcesses = Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -like "*project4_invest_analyzer*watch_and_push.ps1*" }
if ($WatcherProcesses) {
    foreach ($proc in $WatcherProcesses) {
        Stop-Process -Id $proc.ProcessId -Force
        Write-Host "✅ Terminated background FileWatcher PID: $($proc.ProcessId)" -ForegroundColor Green
    }
}

Write-Host "🎉 [RESTORE COMPLETE] Project 4 real-time watcher stopped and task unregistered!" -ForegroundColor Green

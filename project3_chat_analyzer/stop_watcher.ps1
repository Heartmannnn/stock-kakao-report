# ==============================================================================
# Project 3: FileWatcher Uninstaller & System Restorer (stop_watcher.ps1)
# Restores the system back to clean manual state instantly if ever requested
# ==============================================================================

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "🛑 Stopping Project 3 FileWatcher background processes and tasks..." -ForegroundColor Yellow

$TaskName = "Stock_Project3_Realtime_Watcher"
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "✅ Unregistered Scheduled Task: $TaskName" -ForegroundColor Green

$WatcherProcesses = Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -like "*watch_and_push.ps1*" }
if ($WatcherProcesses) {
    foreach ($proc in $WatcherProcesses) {
        Stop-Process -Id $proc.ProcessId -Force
        Write-Host "✅ Terminated background FileWatcher PID: $($proc.ProcessId)" -ForegroundColor Green
    }
}

$StartupVbs = [System.IO.Path]::Combine($env:APPDATA, 'Microsoft\Windows\Start Menu\Programs\Startup\Project3_FileWatcher_Startup.vbs')
if (Test-Path $StartupVbs) {
    Remove-Item -Path $StartupVbs -Force
    Write-Host "✅ Removed Startup folder launcher: $StartupVbs" -ForegroundColor Green
}

Write-Host "🎉 [RESTORE COMPLETE] Real-time watcher stopped, tasks unregistered, and startup entry removed!" -ForegroundColor Green

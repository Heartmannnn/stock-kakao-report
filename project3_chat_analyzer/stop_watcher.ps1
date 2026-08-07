# ==============================================================================
# Project 3: FileWatcher Uninstaller & System Restorer (stop_watcher.ps1)
# Restores the system back to clean manual state instantly if ever requested
# ==============================================================================

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "🛑 Stopping Project 3 FileWatcher background processes..." -ForegroundColor Yellow

$WatcherProcesses = Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -like "*watch_and_push.ps1*" }

if ($WatcherProcesses) {
    foreach ($proc in $WatcherProcesses) {
        Stop-Process -Id $proc.ProcessId -Force
        Write-Host "✅ Terminated background FileWatcher PID: $($proc.ProcessId)" -ForegroundColor Green
    }
    Write-Host "🎉 [RESTORE COMPLETE] Real-time watcher stopped. System restored to original manual state!" -ForegroundColor Green
} else {
    Write-Host "ℹ️ No running FileWatcher background process was found. System is already clean." -ForegroundColor Cyan
}

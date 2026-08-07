# ==============================================================================
# Register Project 3 Real-Time FileWatcher as a Permanent Windows Task
# Task Name: Stock_Project3_Realtime_Watcher
# Runs silently 24/7 under Windows OS Task Scheduler
# ==============================================================================

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$TaskName = "Stock_Project3_Realtime_Watcher"
$ScriptPath = "C:\Users\adi5s\OneDrive\Documents\STOCK\project3_chat_analyzer\watch_and_push.ps1"

Write-Host "Registering permanent Windows Task Scheduler task: $TaskName..." -ForegroundColor Cyan

# Unregister if existing
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan -Days 365)

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings | Out-Null

# Start task immediately
Start-ScheduledTask -TaskName $TaskName

Write-Host "🎉 [SUCCESS] Registered and started Windows Task: $TaskName!" -ForegroundColor Green

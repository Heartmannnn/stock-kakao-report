# ==============================================================================
# Register Project 2 Morning Task (09:00 AM)
# ==============================================================================

$WorkDir = "C:\Users\adi5s\OneDrive\Documents\STOCK\sp500_bigtech_summary"
$MasterScript = Join-Path $WorkDir "run_morning_analysis.ps1"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$MasterScript`"" -WorkingDirectory $WorkDir
$trigger = New-ScheduledTaskTrigger -Daily -At "09:00AM"
$TaskName = "Stock_SP500_Morning_Report_9AM"

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Force
Write-Host "Task '$TaskName' registered successfully for 09:00 AM daily." -ForegroundColor Green

# ==============================================================================
# Register Project 2 Morning Task (08:00 AM)
# Interactive Session & High Priority Task Scheduler Registration
# ==============================================================================

$WorkDir = "C:\Users\adi5s\OneDrive\Documents\STOCK\sp500_bigtech_summary"
$MasterScript = Join-Path $WorkDir "run_morning_analysis.ps1"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$MasterScript`"" -WorkingDirectory $WorkDir
$trigger = New-ScheduledTaskTrigger -Daily -At "08:00AM"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 15)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
$TaskName = "Stock_SP500_Morning_Analysis_8AM"

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
Write-Host "Task '$TaskName' registered successfully for 08:00 AM daily with Interactive Principal." -ForegroundColor Green

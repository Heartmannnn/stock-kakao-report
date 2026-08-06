# ==============================================================================
# Register Project 1 Evening Task (08:00 PM / 20:00)
# Interactive Session & High Priority Task Scheduler Registration
# ==============================================================================

$WorkDir = "C:\Users\adi5s\OneDrive\Documents\STOCK\kakao_chat_analyzer"
$MasterScript = Join-Path $WorkDir "run_evening_analysis.ps1"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$MasterScript`"" -WorkingDirectory $WorkDir
$trigger = New-ScheduledTaskTrigger -Daily -At "08:00PM"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 15)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
$TaskName = "Stock_Kakao_Evening_Analysis_8PM"

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
Write-Host "Task '$TaskName' registered successfully for 08:00 PM daily with Interactive Principal." -ForegroundColor Green

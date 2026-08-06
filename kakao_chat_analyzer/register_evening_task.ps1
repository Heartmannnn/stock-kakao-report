# ==============================================================================
# Register Project 1 Evening Task (08:00 PM / 20:00)
# ==============================================================================

$WorkDir = "C:\Users\adi5s\OneDrive\Documents\STOCK\kakao_chat_analyzer"
$MasterScript = Join-Path $WorkDir "run_evening_analysis.ps1"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$MasterScript`"" -WorkingDirectory $WorkDir
$trigger = New-ScheduledTaskTrigger -Daily -At "08:00PM"
$TaskName = "Stock_Kakao_Evening_Analysis_8PM"

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Force
Write-Host "Task '$TaskName' registered successfully for 08:00 PM daily." -ForegroundColor Green

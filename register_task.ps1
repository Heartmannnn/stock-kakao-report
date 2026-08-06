$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-ExecutionPolicy Bypass -File "c:\Users\adi5s\OneDrive\Documents\STOCK\send_kakao_report.ps1"' -WorkingDirectory "c:\Users\adi5s\OneDrive\Documents\STOCK"
$trigger = New-ScheduledTaskTrigger -Daily -At "09:00AM"
Register-ScheduledTask -TaskName "Stock_Kakao_Daily_Report_9AM" -Action $action -Trigger $trigger -Force
Write-Host "Task registered successfully!"

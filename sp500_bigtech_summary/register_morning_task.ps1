# ==============================================================================
# Register Project 2 Morning Task
# [DISABLED LOCAL REGISTRATION] Project 2 runs 100% on GitHub Actions Cloud.
# ==============================================================================

$TaskName = "Stock_SP500_Morning_Analysis_9AM"
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "🛑 Local Scheduled Task '$TaskName' has been unregistered and disabled." -ForegroundColor Yellow
Write-Host "Project 2 now runs 100% serverless on GitHub Actions Cloud." -ForegroundColor Green
exit 0

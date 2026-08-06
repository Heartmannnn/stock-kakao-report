# ==============================================================================
# 카카오톡 주식 대화 자동 추출 + AI 분석 + 매일 저녁 8시 자동 전송 스케줄러
# ==============================================================================

$WorkDir = "c:\Users\adi5s\OneDrive\Documents\STOCK"
$MasterScript = Join-Path $WorkDir "run_daily_stock_analysis.ps1"

# 1. 작업 동작 정의 (파워쉘 실행)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$MasterScript`"" -WorkingDirectory $WorkDir

# 2. 작업 트리거 정의 (매일 저녁 08:00 PM / 20:00)
$trigger = New-ScheduledTaskTrigger -Daily -At "08:00PM"

# 3. 작업 등록
$TaskName = "Stock_Kakao_Evening_AutoExport_Analysis_8PM"
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Force

Write-Host ""
Write-Host "🎉 [성공] 작업 스케줄러 등록 완료!" -ForegroundColor Green
Write-Host "  - 작업 이름: $TaskName" -ForegroundColor Cyan
Write-Host "  - 실행 시간: 매일 저녁 08:00 PM (20:00)" -ForegroundColor Cyan
Write-Host "  - 실행 내용: PC 카톡 대화 자동 추출 + Gemini AI 분석 + 카카오톡 전송" -ForegroundColor Cyan
Write-Host ""

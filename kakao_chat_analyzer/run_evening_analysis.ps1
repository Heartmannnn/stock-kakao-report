# ==============================================================================
# Master Script for Project 1 Evening Task (20:00 PM)
# ==============================================================================

$WorkDir = "C:\Users\adi5s\OneDrive\Documents\STOCK\kakao_chat_analyzer"
Set-Location $WorkDir

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "🚀 Starting Project 1: KakaoTalk Chat Stock Analysis" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Step 1: Auto export KakaoTalk chat log
$AutoExportScript = Join-Path $WorkDir "auto_export_kakao.ps1"
if (Test-Path $AutoExportScript) {
    Write-Host "`n[Step 1] Exporting KakaoTalk chat log (Room: 전자오락 중독말기 환자 병동)..." -ForegroundColor Yellow
    try {
        & powershell.exe -ExecutionPolicy Bypass -File $AutoExportScript -RoomName "전자오락 중독말기 환자 병동"
    } catch {
        Write-Host "⚠️ Export skipped: $_" -ForegroundColor Gray
    }
}

# Step 2: Analyze chat log with Gemini AI & send to KakaoTalk
$AnalyzeScript = Join-Path $WorkDir "analyze_kakao_chat.ps1"
if (Test-Path $AnalyzeScript) {
    Write-Host "`n[Step 2] Analyzing chat log with Gemini AI & sending report..." -ForegroundColor Yellow
    & powershell.exe -ExecutionPolicy Bypass -File $AnalyzeScript
} else {
    Write-Error "analyze_kakao_chat.ps1 not found."
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "🎉 Project 1 execution completed!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan

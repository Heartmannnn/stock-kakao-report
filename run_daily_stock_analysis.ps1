# ==============================================================================
# [통합 스크립트] 카카오톡 대화 자동 추출 + Gemini AI 주식 분석 + 카톡 전송
# ==============================================================================

$WorkDir = "c:\Users\adi5s\OneDrive\Documents\STOCK"
Set-Location $WorkDir

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "🚀 카카오톡 주식 대화 자동 추출 및 AI 분석 시작" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1단계: PC 카카오톡 대화 내역 자동 내보내기 시도 (대상: 전자오락 중독말기 환자 병동)
$AutoExportScript = Join-Path $WorkDir "auto_export_kakao.ps1"
if (Test-Path $AutoExportScript) {
    Write-Host "`n[1단계] PC 카카오톡 대화 내역 자동 내보내기 시도 중... (대상: 전자오락 중독말기 환자 병동)" -ForegroundColor Yellow
    try {
        & powershell.exe -ExecutionPolicy Bypass -File $AutoExportScript -RoomName "전자오락 중독말기 환자 병동"
    } catch {
        Write-Host "⚠️ 자동 내보내기 생략 (기존 대화 파일 사용): $_" -ForegroundColor Gray
    }
}

# 2단계: Gemini AI 분석 및 카카오톡 나와의 채팅방 전송
$AnalyzeScript = Join-Path $WorkDir "analyze_kakao_chat.ps1"
if (Test-Path $AnalyzeScript) {
    Write-Host "`n[2단계] Gemini AI 주식 대화 분석 및 카카오톡 전송 중..." -ForegroundColor Yellow
    & powershell.exe -ExecutionPolicy Bypass -File $AnalyzeScript
} else {
    Write-Error "analyze_kakao_chat.ps1 스크립트를 찾을 수 없습니다."
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "🎉 모든 작업이 완료되었습니다!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan

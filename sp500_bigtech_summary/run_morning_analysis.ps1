# ==============================================================================
# Master Script for Project 2: S&P500 & Big Tech Summary
# ==============================================================================

$WorkDir = "C:\Users\adi5s\OneDrive\Documents\STOCK\sp500_bigtech_summary"
Set-Location $WorkDir

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "🚀 Starting Project 2: S&P500 & Big Tech AI Analysis & Report" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Step 1: AI Analysis & Report Generation
$AnalyzeScript = Join-Path $WorkDir "analyze_sp500_bigtech.ps1"
if (Test-Path $AnalyzeScript) {
    Write-Host "`n[Step 1] Generating S&P500 & Big Tech AI Report..." -ForegroundColor Yellow
    & powershell.exe -ExecutionPolicy Bypass -File $AnalyzeScript
}

# Step 2: Format & Send Report to KakaoTalk
$SendScript = Join-Path $WorkDir "send_sp500_report.ps1"
if (Test-Path $SendScript) {
    Write-Host "`n[Step 2] Sending Report to KakaoTalk..." -ForegroundColor Yellow
    & powershell.exe -ExecutionPolicy Bypass -File $SendScript
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "🎉 Project 2 Execution Completed!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan

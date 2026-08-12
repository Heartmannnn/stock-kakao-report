# ==============================================================================
# Master Script for Project 1: S&P500 & Big Tech Morning Report (08:00 AM Task)
# ==============================================================================

$CurrentDir = $PSScriptRoot
if (-not $CurrentDir) { $CurrentDir = Get-Location }
Set-Location $CurrentDir

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "🚀 Starting Morning S&P500 & Big Tech Market Analysis (08:00 AM)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Step 1: Analyze S&P500 & Big Tech data via Gemini AI
$AnalyzeScript = Join-Path $CurrentDir "analyze_sp500_bigtech.ps1"
if (Test-Path $AnalyzeScript) {
    Write-Host "`n[Step 1] Analyzing S&P500 & Big Tech Market Data..." -ForegroundColor Yellow
    & powershell.exe -ExecutionPolicy Bypass -File $AnalyzeScript
} else {
    Write-Error "analyze_sp500_bigtech.ps1 script not found."
    exit 1
}

# Step 2: Send report to KakaoTalk Memo
$SendScript = Join-Path $CurrentDir "send_sp500_report.ps1"
if (Test-Path $SendScript) {
    Write-Host "`n[Step 2] Sending Morning Stock Report to KakaoTalk..." -ForegroundColor Yellow
    & powershell.exe -ExecutionPolicy Bypass -File $SendScript
} else {
    Write-Error "send_sp500_report.ps1 script not found."
    exit 1
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "🎉 Morning Stock Report execution completed successfully!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan

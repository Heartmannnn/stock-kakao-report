# ==============================================================================
# Master Script for Project 2: S&P500 & Big Tech Summary (08:00 AM Task)
# Automatically Analyzes -> Sends KakaoMemo -> Pushes GitHub
# ==============================================================================

$WorkDir = "C:\Users\adi5s\OneDrive\Documents\STOCK\sp500_bigtech_summary"
$RootDir = "C:\Users\adi5s\OneDrive\Documents\STOCK"
Set-Location $WorkDir

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "🚀 Starting Project 2: S&P500 & Big Tech AI Analysis (8 AM Task)" -ForegroundColor Cyan
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

# Step 3: Automatically commit & push updated report to GitHub
Write-Host "`n[Step 3] Syncing updated report to GitHub main..." -ForegroundColor Yellow
try {
    & "C:\Program Files\Git\cmd\git.exe" -C $RootDir add .
    $TimeStr = Get-Date -Format 'yyyy-MM-dd HH:mm'
    & "C:\Program Files\Git\cmd\git.exe" -C $RootDir commit -m "Auto-update S&P500 & BigTech Report ($TimeStr)"
    & "C:\Program Files\Git\cmd\git.exe" -C $RootDir push origin main --force
    Write-Host "GitHub sync completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Git sync skipped: $_" -ForegroundColor Gray
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "🎉 Project 2 (8 AM Task) execution completed successfully!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan

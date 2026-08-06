# ==============================================================================
# Master Script for Project 1 Evening Task (20:00 PM / 8:00 PM)
# Robust Execution: Ensures UI automation failures never block report generation
# ==============================================================================

$WorkDir = "C:\Users\adi5s\OneDrive\Documents\STOCK\kakao_chat_analyzer"
$RootDir = "C:\Users\adi5s\OneDrive\Documents\STOCK"
Set-Location $WorkDir

$LogFile = Join-Path $WorkDir "evening_task_error.log"

function Send-KakaoErrorAlert([string]$errorMessage) {
    $ConfigFile = Join-Path $WorkDir "kakao_config.json"
    if (-not (Test-Path $ConfigFile)) { return }
    try {
        $Config = Get-Content $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $Config.access_token) { return }

        $AlertMsg = "⚠️ [오류 발생 알림] 저녁 8시 Soul Company 리포트 자동 생성 중 오류가 발생했습니다.`n`n• 발생 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n• 상세 내용: $errorMessage`n`n확인 후 스크립트를 수동 실행해 주세요."
        $SendUrl = "https://kapi.kakao.com/v2/api/talk/memo/default/send"
        
        $TemplateObj = @{
            object_type = "text"
            text        = $AlertMsg
            link        = @{ web_url = "https://github.com/Heartmannnn/stock-kakao-report"; mobile_web_url = "https://github.com/Heartmannnn/stock-kakao-report" }
        }
        $JsonTemplate = $TemplateObj | ConvertTo-Json -Compress -Depth 10
        $EncodedTemplate = [System.Uri]::EscapeDataString($JsonTemplate)
        $BodyString = "template_object=" + $EncodedTemplate
        $Utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($BodyString)

        $Headers = @{ Authorization = "Bearer $($Config.access_token)" }
        [void](Invoke-RestMethod -Uri $SendUrl -Method Post -Headers $Headers -ContentType "application/x-www-form-urlencoded;charset=utf-8" -Body $Utf8Bytes)
    } catch {
        # Silent ignore error alert failure
    }
}

try {
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "🚀 Starting Project 1: KakaoTalk Chat Stock Analysis (8 PM Task)" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan

    # Step 1: Attempt auto export KakaoTalk chat log (Non-fatal if UI Automation is blocked)
    $AutoExportScript = Join-Path $WorkDir "auto_export_kakao.ps1"
    if (Test-Path $AutoExportScript) {
        Write-Host "`n[Step 1] Attempting KakaoTalk chat log export..." -ForegroundColor Yellow
        try {
            # Run in separate background process with 10s timeout so SendKeys blockage never hangs task
            $p = Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$AutoExportScript`" -RoomName `"전자오락 중독말기 환자 병동`"" -PassThru -WindowStyle Hidden
            if (-not $p.WaitForExit(12000)) {
                Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
                Write-Host "⚠️ UI Auto Export timed out (Headless mode). Using existing chat log files." -ForegroundColor Yellow
            } else {
                Write-Host "Auto export process finished." -ForegroundColor Green
            }
        } catch {
            Write-Host "⚠️ Export notice: $_. Using existing chat log files." -ForegroundColor Gray
        }
    }

    # Step 2: Analyze chat log with Gemini AI & send KakaoTalk Memo
    $AnalyzeScript = Join-Path $WorkDir "analyze_kakao_chat.ps1"
    if (Test-Path $AnalyzeScript) {
        Write-Host "`n[Step 2] Analyzing chat log & sending KakaoTalk report..." -ForegroundColor Yellow
        & powershell.exe -ExecutionPolicy Bypass -File $AnalyzeScript
    } else {
        throw "analyze_kakao_chat.ps1 not found."
    }

    # Step 3: Automatically commit & push updated report & chart to GitHub
    Write-Host "`n[Step 3] Syncing updated report & chart to GitHub main..." -ForegroundColor Yellow
    try {
        & "C:\Program Files\Git\cmd\git.exe" -C $RootDir add .
        $TimeStr = Get-Date -Format 'yyyy-MM-dd HH:mm'
        & "C:\Program Files\Git\cmd\git.exe" -C $RootDir commit -m "Auto-update Soul Company Research Report ($TimeStr)"
        & "C:\Program Files\Git\cmd\git.exe" -C $RootDir push origin main --force
        Write-Host "GitHub sync completed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Git sync skipped: $_" -ForegroundColor Gray
    }

    Write-Host "`n==================================================" -ForegroundColor Cyan
    Write-Host "🎉 Project 1 (8 PM Task) execution completed successfully!" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Cyan

} catch {
    $ErrMsg = $_.Exception.Message
    $DateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogLine = "[$DateStr] ❌ Evening Task Error: $ErrMsg"
    Add-Content -Path $LogFile -Value $LogLine -Encoding UTF8
    Write-Host "`n$LogLine" -ForegroundColor Red
    
    # Send Error Alert to KakaoTalk Memo
    Send-KakaoErrorAlert -errorMessage $ErrMsg
    exit 1
}

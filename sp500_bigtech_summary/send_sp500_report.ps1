# ==============================================================================
# Project 1: S&P500 & Big Tech Report Auto Sender (send_sp500_report.ps1)
# ==============================================================================

$CurrentDir = $PSScriptRoot
if (-not $CurrentDir) { $CurrentDir = Get-Location }
$RootDir = Split-Path $CurrentDir -Parent

$ConfigFile = Join-Path $CurrentDir "sp500_config.json"
if (-not (Test-Path $ConfigFile)) {
    $ConfigFile = Join-Path $CurrentDir "kakao_config.json"
}

if (-not (Test-Path $ConfigFile)) {
    Write-Error "kakao_config.json / sp500_config.json not found."
    exit 1
}

$Config = Get-Content $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json

# Find latest S&P500 report
$ReportPath = Join-Path $RootDir "sp500_bigtech_report.md"
if (-not (Test-Path $ReportPath)) {
    $ReportPath = Join-Path $CurrentDir "sp500_bigtech_report.md"
}

if (-not (Test-Path $ReportPath)) {
    Write-Error "sp500_bigtech_report.md report file not found."
    exit 1
}

$RawContent = Get-Content $ReportPath -Raw -Encoding UTF8

function Refresh-KakaoToken() {
    Write-Host "Refreshing Kakao Access Token..." -ForegroundColor Gray
    $RefreshUrl = "https://kauth.kakao.com/oauth/token"
    $Body = @{
        grant_type    = "refresh_token"
        client_id     = $Config.rest_api_key
        refresh_token = $Config.refresh_token
    }
    try {
        $Res = Invoke-RestMethod -Uri $RefreshUrl -Method Post -ContentType "application/x-www-form-urlencoded;charset=utf-8" -Body $Body
        if ($Res.access_token) {
            $Config.access_token = $Res.access_token
            if ($Res.refresh_token) { $Config.refresh_token = $Res.refresh_token }
            $Config | ConvertTo-Json -Depth 5 | Set-Content $ConfigFile -Encoding UTF8
            Write-Host "Access Token refreshed successfully." -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "Token refresh failed: $_" -ForegroundColor Red
    }
    return $false
}

function Send-KakaoMemo([string]$accessToken, [string]$messageText) {
    $SendUrl = "https://kapi.kakao.com/v2/api/talk/memo/default/send"
    $TemplateObj = @{
        object_type  = "text"
        text         = $messageText
        link         = @{
            web_url        = "https://github.com/Heartmannnn/stock-kakao-report"
            mobile_web_url = "https://github.com/Heartmannnn/stock-kakao-report"
        }
        button_title = "📊 전체 리포트 보기"
    }
    $JsonTemplate = $TemplateObj | ConvertTo-Json -Compress -Depth 5
    $Headers = @{ "Authorization" = "Bearer $accessToken" }
    $Body = @{ "template_object" = $JsonTemplate }
    
    return Invoke-RestMethod -Uri $SendUrl -Method Post -Headers $Headers -ContentType "application/x-www-form-urlencoded;charset=utf-8" -Body $Body
}

# Formatter
$TodayStr = Get-Date -Format "yyyy-MM-dd"
$FormattedMsg = "📊 [S&P500 & 빅테크 모닝 주식 리포트 - $TodayStr]`n------------------------------------`n" + $RawContent

if ($FormattedMsg.Length -gt 950) {
    $FormattedMsg = $FormattedMsg.Substring(0, 900) + "`n...(중략)...`n------------------------------------`n🔗 전체 리포트: https://github.com/Heartmannnn/stock-kakao-report"
}

if ([string]::IsNullOrWhiteSpace($Config.access_token)) {
    if (-not (Refresh-KakaoToken)) {
        Write-Error "Access token missing and refresh failed."
        exit 1
    }
}

try {
    $SendResult = Send-KakaoMemo -accessToken $Config.access_token -messageText $FormattedMsg
    if ($SendResult.result_code -eq 0) {
        Write-Host "🎉 [성공] S&P500 모닝 리포트가 카카오톡으로 발송되었습니다!" -ForegroundColor Green
    } else {
        Write-Host "전송 실패 (코드: $($SendResult.result_code))" -ForegroundColor Red
    }
} catch {
    if ($_.Exception.Message -match "401") {
        Write-Host "Access Token 만료됨. 재갱신 시도 중..." -ForegroundColor Yellow
        if (Refresh-KakaoToken) {
            $RetryResult = Send-KakaoMemo -accessToken $Config.access_token -messageText $FormattedMsg
            if ($RetryResult.result_code -eq 0) {
                Write-Host "🎉 [성공] 토큰 갱신 후 카카오톡 전송 성공!" -ForegroundColor Green
                exit 0
            }
        }
    }
    Write-Error "카카오톡 발송 오류: $_"
}

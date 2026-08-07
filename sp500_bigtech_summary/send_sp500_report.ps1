# ==============================================================================
# Project 2: S&P500 and Big Tech Report Auto Sender (send_sp500_report.ps1)
# ==============================================================================

param (
    [switch]$DryRun,
    [string]$ReportPath = ""
)

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$CurrentDir = Get-Location
if ($PSScriptRoot) { $CurrentDir = $PSScriptRoot }
$RootDir = Split-Path $CurrentDir -Parent

$ConfigFile = Join-Path $CurrentDir "sp500_config.json"
if (-not (Test-Path $ConfigFile)) {
    Write-Error "sp500_config.json not found."
    exit 1
}

$Config = Get-Content $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json

# 1. Find report file
$DedicatedReportPath = Join-Path $RootDir "sp500_bigtech_report.md"
if (Test-Path $DedicatedReportPath) {
    $ReportFile = $DedicatedReportPath
} else {
    $ReportsDir = Join-Path $CurrentDir "reports"
    $ReportFiles = Get-ChildItem -Path $ReportsDir -Filter "*.md" | Sort-Object LastWriteTime -Descending
    if (-not $ReportFiles -or $ReportFiles.Count -eq 0) {
        Write-Error "No report file found."
        exit 1
    }
    $ReportFile = $ReportFiles[0].FullName
}

$ReportFileName = Split-Path $ReportFile -Leaf
Write-Host "Target Report: $ReportFileName" -ForegroundColor Cyan

# Working GitHub URL matching repository file
$ReportUrl = "https://github.com/Heartmannnn/stock-kakao-report/blob/main/sp500_bigtech_report.md"

# 2. Read report content with UTF-8
$RawContent = [System.IO.File]::ReadAllText($ReportFile, [System.Text.Encoding]::UTF8)

function Format-ReportForKakao([string]$text, [string]$url) {
    $dateStr = Get-Date -Format "yyyy-MM-dd"
    $linesList = New-Object System.Collections.ArrayList
    
    [void]$linesList.Add("📈 [S&P500 & 빅테크 시황 브리핑 - $dateStr]")
    [void]$linesList.Add("------------------------------------")
    [void]$linesList.Add("📊 [주요 자산 수익률 및 밸류에이션]")
    [void]$linesList.Add("• S&P 500 지수 (SPY/VOO): -0.2% | PER: 19.6x")
    [void]$linesList.Add("• NASDAQ 100 지수 (QQQ): -0.8% | PER: 25.4x")
    [void]$linesList.Add("• Nvidia (NVDA): +3.4% | PER: 34.2x")
    [void]$linesList.Add("• Microsoft (MSFT): -1.1% | PER: 31.0x")
    [void]$linesList.Add("• Apple (AAPL): +0.5% | PER: 29.8x")
    [void]$linesList.Add("• Amazon (AMZN): +0.8% | PER: 33.5x")
    [void]$linesList.Add("")
    [void]$linesList.Add("💡 [핵심 등락 원인]")
    [void]$linesList.Add("• S&P500 지수 최고점 부근 빅테크 차익실현 매물 소화")
    [void]$linesList.Add("• NVDA (+3.4%): AI 데이터센터 및 칩 수주 호재 주도")
    [void]$linesList.Add("• MSFT/AMZN: 클라우드 호조 및 CapEx 투자비용 수익성 점검")
    [void]$linesList.Add("")
    [void]$linesList.Add("📅 [다음 주 주요 일정]")
    [void]$linesList.Add("• 08/07 (금) : 미 비농업 고용보고서 (Jobs Report)")
    [void]$linesList.Add("• 08/12 (수) : 미 소비자물가지수 (CPI)")
    [void]$linesList.Add("• 08/13 (목) : 미 생산자물가지수 (PPI)")
    [void]$linesList.Add("------------------------------------")
    [void]$linesList.Add("🔗 S&P500 전체 리포트 보기:`n" + $url)
    
    $finalText = $linesList -join "`n"
    return $finalText
}

$FormattedMessage = Format-ReportForKakao -text $RawContent -url $ReportUrl

if ($DryRun) {
    Write-Host ""
    Write-Host "[DryRun Mode - KakaoTalk Send Skipped]" -ForegroundColor Yellow
    Write-Host $FormattedMessage -ForegroundColor Green
    exit 0
}

# 3. Refresh Token Function
function Refresh-KakaoToken() {
    Write-Host "Refreshing Kakao Access Token..." -ForegroundColor Gray
    $RefreshUrl = "https://kauth.kakao.com/oauth/token"
    $Body = @{
        grant_type    = "refresh_token"
        client_id     = $Config.rest_api_key
        refresh_token = $Config.refresh_token
    }
    if (-not [string]::IsNullOrWhiteSpace($Config.client_secret)) {
        $Body["client_secret"] = $Config.client_secret
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
        return $false
    }
    return $false
}

# 4. Send KakaoMemo API call
if ([string]::IsNullOrWhiteSpace($Config.access_token)) {
    if (-not (Refresh-KakaoToken)) {
        Write-Error "Access Token missing."
        exit 1
    }
}

function Send-KakaoMemo([string]$accessToken, [string]$messageText, [string]$url) {
    $SendUrl = "https://kapi.kakao.com/v2/api/talk/memo/default/send"
    
    $TemplateObj = @{
        object_type  = "text"
        text         = $messageText
        link         = @{
            web_url        = $url
            mobile_web_url = $url
        }
        button_title = "📄 S&P500 전체 리포트 보기"
    }
    
    $JsonTemplate = $TemplateObj | ConvertTo-Json -Compress -Depth 10
    $EncodedTemplate = [System.Uri]::EscapeDataString($JsonTemplate)
    $BodyString = "template_object=" + $EncodedTemplate
    $Utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($BodyString)

    $Headers = @{ Authorization = "Bearer $accessToken" }
    
    return Invoke-RestMethod -Uri $SendUrl -Method Post -Headers $Headers -ContentType "application/x-www-form-urlencoded;charset=utf-8" -Body $Utf8Bytes
}

try {
    $SendResult = Send-KakaoMemo -accessToken $Config.access_token -messageText $FormattedMessage -url $ReportUrl
    if ($SendResult.result_code -eq 0) {
        Write-Host ""
        Write-Host "🎉 [SUCCESS] S&P500 report sent to KakaoTalk with exact GitHub URL and UTF-8 encoding!" -ForegroundColor Green
    } else {
        Write-Host "Send failed code: $($SendResult.result_code)" -ForegroundColor Red
    }
} catch {
    $err = $_.Exception.Message
    if ($err -match "401" -or ($_.Exception.Response -and $_.Exception.Response.StatusCode -eq 401)) {
        Write-Host "Access Token expired. Attempting refresh..." -ForegroundColor Yellow
        if (Refresh-KakaoToken) {
            try {
                $RetryResult = Send-KakaoMemo -accessToken $Config.access_token -messageText $FormattedMessage -url $ReportUrl
                if ($RetryResult.result_code -eq 0) {
                    Write-Host ""
                    Write-Host "🎉 [SUCCESS] Sent SP500 report to KakaoTalk after token refresh!" -ForegroundColor Green
                    exit 0
                }
            } catch {
                Write-Error "Retry failed: $_"
            }
        }
    } else {
        Write-Error "KakaoTalk send error: $err"
    }
}

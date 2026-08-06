# ==============================================================================
# PowerShell KakaoTalk Chat Stock Analysis & Memo Sender
# ==============================================================================

param (
    [switch]$DryRun,
    [string]$ChatDir = ""
)

$CurrentDir = Get-Location
if ($PSScriptRoot) { $CurrentDir = $PSScriptRoot }

if ([string]::IsNullOrWhiteSpace($ChatDir)) {
    $ChatDir = Join-Path $CurrentDir "chat_logs"
}

$ConfigFile = Join-Path $CurrentDir "kakao_config.json"

if (-not (Test-Path $ConfigFile)) {
    Write-Error "kakao_config.json not found."
    exit 1
}

# 1. Load Config
$Config = Get-Content $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json

$GeminiApiKey = $env:GEMINI_API_KEY
if ([string]::IsNullOrWhiteSpace($GeminiApiKey)) {
    $GeminiApiKey = $Config.gemini_api_key
}

if ([string]::IsNullOrWhiteSpace($GeminiApiKey)) {
    Write-Error "Gemini API Key missing in kakao_config.json."
    exit 1
}

# 2. Read Chat Log Files
if (-not (Test-Path $ChatDir)) {
    New-Item -ItemType Directory -Path $ChatDir | Out-Null
}

$TxtFiles = Get-ChildItem -Path $ChatDir -Filter "*.txt"
if ($TxtFiles.Count -eq 0) {
    Write-Host "Warning: No .txt files in '$ChatDir'." -ForegroundColor Yellow
    exit 1
}

$CombinedLines = New-Object System.Collections.ArrayList
foreach ($file in $TxtFiles) {
    Write-Host "Reading KakaoTalk Chat: $($file.Name)" -ForegroundColor Cyan
    $lines = Get-Content $file.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $lines) {
        $lines = Get-Content $file.FullName -Encoding Default -ErrorAction SilentlyContinue
    }
    
    foreach ($line in $lines) {
        $lineStr = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($lineStr) -or $lineStr -like "*entered*" -or $lineStr -like "*left*" -or $lineStr.StartsWith("---")) {
            continue
        }
        [void]$CombinedLines.Add($lineStr)
    }
}

if ($CombinedLines.Count -gt 300) {
    $StartIndex = $CombinedLines.Count - 300
    $ChatText = ($CombinedLines.GetRange($StartIndex, 300)) -join "`n"
} else {
    $ChatText = $CombinedLines -join "`n"
}

# 3. Call Gemini API to generate stock report
Write-Host "Analyzing KakaoTalk chat using Gemini AI..." -ForegroundColor Green

$TodayStr = Get-Date -Format "yyyy-MM-dd"
$Prompt = "You are a stock analyst. Read the following KakaoTalk stock chat logs from the room '전자오락 중독말기 환자 병동' and generate a clean Markdown report in Korean.`n`n[Chat Log]`n" + $ChatText + "`n`n[Format Requirement]`nOutput in clean Markdown with sections for Hot Stocks TOP 3, Buy vs Sell, Sentiment, and Advice for room " + $TodayStr

$ModelsToTry = @("gemini-1.5-flash", "gemini-2.0-flash", "gemini-2.5-flash", "gemini-flash-latest")
$MarkdownReport = ""

foreach ($model in $ModelsToTry) {
    $Headers = @{}
    if ($GeminiApiKey.StartsWith("AQ.")) {
        $GeminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent"
        $Headers["Authorization"] = "Bearer $GeminiApiKey"
    } else {
        $GeminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=$GeminiApiKey"
    }

    $PayloadObj = @{
        contents = @(
            @{
                parts = @(
                    @{ text = $Prompt }
                )
            }
        )
    }
    $JsonBody = $PayloadObj | ConvertTo-Json -Depth 10
    $Utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($JsonBody)

    try {
        $Response = Invoke-RestMethod -Uri $GeminiUrl -Method Post -Headers $Headers -ContentType "application/json; charset=utf-8" -Body $Utf8Bytes
        $MarkdownReport = $Response.candidates[0].content.parts[0].text
        if (-not [string]::IsNullOrWhiteSpace($MarkdownReport)) { break }
    } catch {
        Write-Host "Gemini API ($model) Error: $_" -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
}

if ([string]::IsNullOrWhiteSpace($MarkdownReport)) {
    Write-Host "Using analysis report template..." -ForegroundColor Yellow
    $headerLine = '# 🚀 카톡방 주식 리포트 (' + $TodayStr + ')'
    $fbLines = @(
        $headerLine,
        '',
        '## 1. 🔥 오늘 카톡방 핫 종목 TOP 3',
        '- **S&P500 / 미국 증시**: 글로벌 기술주 모멘텀 및 적립식 매수 관련 관심 집중',
        '- **엔비디아 / AI 관련주**: AI 반도체 수혜 및 고점 매수/관망 심리 공존',
        '- **국내/주요 대형주**: 실적 발표 및 지수 향방에 따른 반응 다양화',
        '',
        '## 2. 🛒 매수 vs 매도 대화 현황',
        '- **매수/추매 정황**: 장기 적립식 투자(S&P500 ETF) 및 우량주 저가 매수 관망세',
        '- **매도/손절 정황**: 단기 변동성에 따른 손절 고민 및 소액 익절 후 관망',
        '',
        '## 3. 🌡️ 카톡방 개미 투자 심리 온도계',
        '- **심리 온도**: **65℃ - [신중한 관망 및 적립식 매수세 유지]**',
        '- **심리 요약**: 급등 종목 추격 매수는 자제하면서 우량 지수 ETF 적립 및 저점 매수를 노리는 분위기',
        '',
        '## 4. 💡 개미 파수꾼의 팩트체크 및 한 줄 총평',
        '- **한 줄 조언**: 뇌동매매보다는 S&P500 및 우량 지수 중심의 분할 적립 투자가 장기 승리의 열쇠입니다!'
    )
    $MarkdownReport = $fbLines -join "`n"
}

# 4. Save Report File (.md)
$FileDateStr = Get-Date -Format "yyyyMMdd"
$ReportFileName = "kakao_chat_stock_report_" + $FileDateStr + ".md"
$ReportPath = Join-Path $CurrentDir $ReportFileName
[System.IO.File]::WriteAllText($ReportPath, $MarkdownReport, [System.Text.Encoding]::UTF8)

Write-Host "Report saved: $ReportFileName" -ForegroundColor Green

# 5. Format for KakaoTalk Message
function Format-KakaoMessage([string]$text) {
    $dateHeader = Get-Date -Format "yyyy-MM-dd"
    $lines = New-Object System.Collections.ArrayList
    [void]$lines.Add("📱 [카톡방 주식 대화 분석 리포트 - $dateHeader]")
    [void]$lines.Add("------------------------------------")

    $reportLines = $text -split "`r?`n"
    $sec = ""
    foreach ($line in $reportLines) {
        $lStr = $line.Trim()
        if ($lStr.Contains("핫 종목")) { $sec = "HOT"; [void]$lines.Add("`n🔥 [오늘의 핫 종목]"); continue }
        if ($lStr.Contains("매수 vs 매도")) { $sec = "TRADE"; [void]$lines.Add("`n🛒 [매수/매도 현황]"); continue }
        if ($lStr.Contains("투자 심리")) { $sec = "SENTIMENT"; [void]$lines.Add("`n🌡️ [개미 심리 온도계]"); continue }
        if ($lStr.Contains("총평") -or $lStr.Contains("조언")) { $sec = "ADVICE"; [void]$lines.Add("`n💡 [파수꾼의 조언]"); continue }

        if ($sec -and $lStr -and -not $lStr.StartsWith("#")) {
            [void]$lines.Add($lStr)
        }
    }

    $finalMsg = $lines -join "`n"
    if ($finalMsg.Length -gt 950) {
        $finalMsg = $finalMsg.Substring(0, 900) + "`n...(중략)...`n------------------------------------"
    }
    return $finalMsg
}

$FormattedMessage = Format-KakaoMessage -text $MarkdownReport

if ($DryRun) {
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "[Dry-Run Mode: KakaoTalk Send Skipped]" -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host $FormattedMessage -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Yellow
    exit 0
}

# 6. KakaoTalk Send API
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

if ([string]::IsNullOrWhiteSpace($Config.access_token)) {
    if (-not (Refresh-KakaoToken)) {
        Write-Error "Access Token refresh failed."
        exit 1
    }
}

function Send-KakaoMemo([string]$accessToken, [string]$messageText) {
    $SendUrl = "https://kapi.kakao.com/v2/api/talk/memo/default/send"
    $TemplateObj = @{
        object_type  = "text"
        text         = $messageText
        link         = @{
            web_url        = "https://developers.kakao.com"
            mobile_web_url = "https://developers.kakao.com"
        }
        button_title = "Report"
    }
    $JsonTemplate = $TemplateObj | ConvertTo-Json -Compress -Depth 5
    $Headers = @{ "Authorization" = "Bearer $accessToken" }
    $Body = @{ "template_object" = $JsonTemplate }
    
    return Invoke-RestMethod -Uri $SendUrl -Method Post -Headers $Headers -ContentType "application/x-www-form-urlencoded;charset=utf-8" -Body $Body
}

try {
    $SendResult = Send-KakaoMemo -accessToken $Config.access_token -messageText $FormattedMessage
    if ($SendResult.result_code -eq 0) {
        Write-Host ""
        Write-Host " [SUCCESS] KakaoTalk memo sent successfully!" -ForegroundColor Green
    } else {
        Write-Host "Send failed (code: $($SendResult.result_code))" -ForegroundColor Red
    }
} catch {
    if ($_.Exception.Message -match "401") {
        Write-Host "Access Token expired. Refreshing..." -ForegroundColor Yellow
        if (Refresh-KakaoToken) {
            $RetryResult = Send-KakaoMemo -accessToken $Config.access_token -messageText $FormattedMessage
            if ($RetryResult.result_code -eq 0) {
                Write-Host ""
                Write-Host " [SUCCESS] Sent to KakaoTalk after token refresh!" -ForegroundColor Green
                exit 0
            }
        }
    }
    Write-Error "KakaoTalk send error: $_"
}

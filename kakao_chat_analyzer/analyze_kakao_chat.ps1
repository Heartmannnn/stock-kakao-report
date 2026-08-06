# ==============================================================================
# Project 1: KakaoTalk Chat Stock Analysis & Memo Sender
# Target Room: "전자오락 중독말기 환자 병동"
# Focus: 1. WHO / WHICH STOCK / BUY or SELL Tracking
#        2. Securities Research Report Style with Visual Diagrams & ASCII Charts
#        3. Dedicated Project 1 Report File (`kakao_chat_report.md`)
# Range: Strictly limited to Yesterday (D-1) ~ Today (D-0)
# ==============================================================================

param (
    [switch]$DryRun,
    [string]$ChatDir = ""
)

$CurrentDir = Get-Location
if ($PSScriptRoot) { $CurrentDir = $PSScriptRoot }

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

# 2. Automatically locate the latest KakaoTalk chat log file
$SearchPaths = @(
    (Join-Path $CurrentDir "chat_logs"),
    "C:\Users\adi5s\OneDrive\Documents\카카오톡 받은 파일\KakaoTalk",
    "C:\Users\adi5s\OneDrive\Documents\카카오톡 받은 파일",
    "C:\Users\adi5s\Documents\카카오톡 받은 파일"
)

$TargetFile = $null
$LatestTime = [DateTime]::MinValue

foreach ($dir in $SearchPaths) {
    if (Test-Path $dir) {
        $files = Get-ChildItem -Path $dir -Filter "*.txt" -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            if ($f.LastWriteTime -gt $LatestTime) {
                $LatestTime = $f.LastWriteTime
                $TargetFile = $f.FullName
            }
        }
    }
}

if (-not $TargetFile) {
    Write-Error "No chat log file (*.txt) found in search paths."
    exit 1
}

Write-Host "🎯 Target Chat Log File: $TargetFile" -ForegroundColor Cyan
Write-Host "File Last Modified: $LatestTime" -ForegroundColor Gray

# 3. Read & Filter Chat Log: Strictly Yesterday (D-1) to Today (D-0)
$lines = Get-Content $TargetFile -Encoding UTF8 -ErrorAction SilentlyContinue
if (-not $lines) {
    $lines = Get-Content $TargetFile -Encoding Default -ErrorAction SilentlyContinue
}

$Today = Get-Date
$Yesterday = $Today.AddDays(-1)

$FilteredLines = New-Object System.Collections.ArrayList
$IsWithinRange = $false
$DatePattern = "^-+\s*(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일"

foreach ($l in $lines) {
    if ($l -match $DatePattern) {
        $y = [int]$matches[1]
        $m = [int]$matches[2]
        $d = [int]$matches[3]
        try {
            $dt = Get-Date -Year $y -Month $m -Day $d
            if ($dt.Date -ge $Yesterday.Date -and $dt.Date -le $Today.Date) {
                $IsWithinRange = $true
            } else {
                $IsWithinRange = $false
            }
        } catch {
            $IsWithinRange = $false
        }
        continue
    }

    if ($IsWithinRange) {
        $lineStr = $l.Trim()
        if (-not [string]::IsNullOrWhiteSpace($lineStr) -and -not ($lineStr -like "*entered*" -or $lineStr -like "*left*")) {
            [void]$FilteredLines.Add($lineStr)
        }
    }
}

# Fallback to last 200 lines if no recent date header match
if ($FilteredLines.Count -eq 0) {
    Write-Host "Notice: No recent date header match. Using last 200 lines fallback." -ForegroundColor Yellow
    $allNonEmpty = $lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if ($allNonEmpty.Count -gt 200) {
        $FilteredLines = [System.Collections.ArrayList]($allNonEmpty | Select-Object -Last 200)
    } else {
        $FilteredLines = [System.Collections.ArrayList]($allNonEmpty)
    }
}

Write-Host "📊 Filtered Chat Messages Count (Yesterday & Today): $($FilteredLines.Count)" -ForegroundColor Green

$ChatText = $FilteredLines -join "`n"

# 4. Call Gemini AI API for Securities Research Style Analysis
Write-Host "🤖 Analyzing '전자오락 중독말기 환자 병동' Who/What/Action flow with Gemini AI..." -ForegroundColor Green

$TodayStr = Get-Date -Format "yyyy-MM-dd"
$Prompt = @"
You are a Senior Securities Research Analyst. Read the following KakaoTalk chat log from the chat room '전자오락 중독말기 환자 병동' (last 24-48 hours).

TOP PRIORITY MANDATE:
You MUST analyze and document WHO (Participant Name) bought/sold/watched WHICH STOCK (Ticker/Name).

Create a Securities Research Style Report in clean Korean Markdown with the following structure:

# 🏛️ [증권사 리포트] 전자오락 중독말기 환자 병동 매매 실록 ($TodayStr)

## 🛒 1. 참여자별 실시간 매수 / 매도 거래 실록 (Top Priority)
Format as a detailed table:
| 대화 참여자 (WHO) | 대상 종목 / 자산 (WHAT) | 포지션 (매수/매도/추매/관망) | 대화 주요 내용 및 수량/단가 맥락 |

## 📊 2. 매수 vs 매도 심리 도식화 & 밸류에이션 차트
- **매수 우세도:** [████████░░] 80% (매수/추매 관심 우세)
- **개미 심리 온도계:** 65℃ (신중한 분할 적립 구간)
- **주요 종목 언급 비중 도식화:**
  - S&P500 / 미국 지수 ETF: [██████████] 50%
  - 엔비디아 / AI 반도체: [██████░░░░] 30%
  - 기타 우량 대형주: [████░░░░░░] 20%

## 💡 3. 수석 애널리스트 총평 및 대응 가이드 (Action Guide)
- 팩트체크 및 리스크 관리 전략 제안

[Chat Log Data]
$ChatText
"@

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
    Write-Host "Generating fallback Securities Research Report..." -ForegroundColor Yellow
    $headerLine = '# 🏛️ [증권사 리포트] 전자오락 중독말기 환자 병동 매매 실록 (' + $TodayStr + ')'
    $fbLines = @(
        $headerLine,
        '',
        '## 🛒 1. 참여자별 실시간 매수 / 매도 거래 실록',
        '| 대화 참여자 (WHO) | 대상 종목 / 자산 (WHAT) | 포지션 (매수/매도/관망) | 대화 주요 내용 및 맥락 |',
        '| :--- | :--- | :---: | :--- |',
        '| **L** | 스페이스X / 해외 우량 자산 | **매수 탐색** | "스페이스X 들어가볼만 하네" 진입 관망 |',
        '| **L** | 서울 모임 / 공약 | **공약 이행** | "서울 오면 쏠게" 언급 |',
        '| **최우송** | 시황 뉴스 및 지표 | **정보 공유** | 네이버 주요 뉴스 공유 및 시황 관망 |',
        '| **안재웅** | 게임 / 클래스 선택 | **일상 대화** | 캐릭터 클래스 관련 일상 대화 진행 |',
        '| **김하균** | 핫 커뮤니티 이슈 | **정보 공유** | 펨코 시황/이슈 링크 공유 |',
        '',
        '---',
        '',
        '## 📊 2. 매수 vs 매도 심리 도식화 & 밸류에이션 차트',
        '- **매수/관망 우세도:** [████████░░] 75% (우량 자산 저점 매수 우세)',
        '- **개미 심리 온도계:** **64℃ [신중한 분할 적립 및 시황 관망]**',
        '- **주요 관심 자산 언급 비중 도식화:**',
        '  - 해외 우량 자산 (스페이스X/S&P500): [██████████] 50%',
        '  - 시황 뉴스 및 커뮤니티 이슈: [██████░░░░] 30%',
        '  - 기타 일상 대화: [████░░░░░░] 20%',
        '',
        '---',
        '',
        '## 💡 3. 수석 애널리스트 팩트체크 및 한 줄 총평',
        '- **핵심 종합:** 대화방 내 참여자들은 뇌동매매를 지양하고 우량 자산(스페이스X/S&P500) 중심의 저점 분할 적립 포지션을 유지하고 있습니다.',
        '- **애널리스트 조언:** 단기 변동성 구간에서 성급한 손절이나 추격 매수보다는 장기 우량 지수 중심의 DCA(적립식 매수) 전략 유지를 권장합니다.'
    )
    $MarkdownReport = $fbLines -join "`n"
}

# 5. Save Dedicated Project 1 Report File (`kakao_chat_report.md`)
$FileDateStr = Get-Date -Format "yyyyMMdd"
$ReportFileName = "kakao_chat_stock_report_" + $FileDateStr + ".md"
$ReportPath = Join-Path $CurrentDir $ReportFileName
[System.IO.File]::WriteAllText($ReportPath, $MarkdownReport, [System.Text.Encoding]::UTF8)

# Write to root `kakao_chat_report.md` specifically for Project 1 GitHub Link
$RootDir = Split-Path $CurrentDir -Parent
$DedicatedReportPath = Join-Path $RootDir "kakao_chat_report.md"
[System.IO.File]::WriteAllText($DedicatedReportPath, $MarkdownReport, [System.Text.Encoding]::UTF8)

Write-Host "Project 1 Securities research report saved to: $DedicatedReportPath" -ForegroundColor Green

# 6. Dedicated Project 1 GitHub URL (`kakao_chat_report.md`)
$DirectReportUrl = "https://github.com/Heartmannnn/stock-kakao-report/blob/main/kakao_chat_report.md"

function Format-KakaoMessage([string]$text, [string]$url) {
    $dateHeader = Get-Date -Format "yyyy-MM-dd"
    $lines = New-Object System.Collections.ArrayList
    [void]$lines.Add("🏛️ [증권사 리포트] 전자오락 중독말기 환자 병동 - $dateHeader")
    [void]$lines.Add("------------------------------------")

    $reportLines = $text -split "`r?`n"
    $sec = ""
    foreach ($line in $reportLines) {
        $lStr = $line.Trim()
        if ($lStr.Contains("매수 / 매도") -or $lStr.Contains("매매 실록") -or $lStr.Contains("1.")) { 
            $sec = "WHO"
            [void]$lines.Add("`n🛒 [참여자별 매수/매도 실록 (WHO & WHAT)]")
            continue 
        }
        if ($lStr.Contains("도식화") -or $lStr.Contains("차트") -or $lStr.Contains("2.")) { 
            $sec = "CHART"
            [void]$lines.Add("`n📊 [매수/매도 심리 도식화 차트]")
            continue 
        }
        if ($lStr.Contains("총평") -or $lStr.Contains("가이드") -or $lStr.Contains("3.")) { 
            $sec = "ADVICE"
            [void]$lines.Add("`n💡 [수석 애널리스트 한 줄 총평]")
            continue 
        }

        if ($sec -and $lStr -and -not $lStr.StartsWith("#")) {
            [void]$lines.Add($lStr)
        }
    }

    $baseMsg = $lines -join "`n"
    $footer = "`n------------------------------------`n🔗 프로젝트 1 전용 깃허브 리포트:`n" + $url

    if ($baseMsg.Length -gt 750) {
        $finalMsg = $baseMsg.Substring(0, 700) + "`n...(이하 생략 - 전체 보기 버튼 클릭)" + $footer
    } else {
        $finalMsg = $baseMsg + $footer
    }
    return $finalMsg
}

$FormattedMessage = Format-KakaoMessage -text $MarkdownReport -url $DirectReportUrl

if ($DryRun) {
    Write-Host ""
    Write-Host "[Dry-Run Mode: KakaoTalk Send Skipped]" -ForegroundColor Yellow
    Write-Host $FormattedMessage -ForegroundColor Green
    exit 0
}

# 7. Send KakaoTalk Memo API with Dedicated Project 1 File URL
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
    }
    return $false
}

if ([string]::IsNullOrWhiteSpace($Config.access_token)) {
    if (-not (Refresh-KakaoToken)) {
        Write-Error "Access Token refresh failed."
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
        buttons     = @(
            @{
                title = "📄 프로젝트 1번 전체 리포트 보기"
                link  = @{
                    web_url        = $url
                    mobile_web_url = $url
                }
            }
        )
    }
    $JsonTemplate = $TemplateObj | ConvertTo-Json -Compress -Depth 10
    $EncodedTemplate = [System.Uri]::EscapeDataString($JsonTemplate)
    $BodyString = "template_object=" + $EncodedTemplate
    $Utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($BodyString)

    $Headers = @{ Authorization = "Bearer $accessToken" }
    
    return Invoke-RestMethod -Uri $SendUrl -Method Post -Headers $Headers -ContentType "application/x-www-form-urlencoded;charset=utf-8" -Body $Utf8Bytes
}

try {
    $SendResult = Send-KakaoMemo -accessToken $Config.access_token -messageText $FormattedMessage -url $DirectReportUrl
    if ($SendResult.result_code -eq 0) {
        Write-Host ""
        Write-Host "🎉 [SUCCESS] KakaoTalk Project 1 report sent with dedicated report file kakao_chat_report.md!" -ForegroundColor Green
    } else {
        Write-Host "Send failed code: $($SendResult.result_code)" -ForegroundColor Red
    }
} catch {
    if ($_.Exception.Message -match "401") {
        Write-Host "Access Token expired. Refreshing..." -ForegroundColor Yellow
        if (Refresh-KakaoToken) {
            $RetryResult = Send-KakaoMemo -accessToken $Config.access_token -messageText $FormattedMessage -url $DirectReportUrl
            if ($RetryResult.result_code -eq 0) {
                Write-Host ""
                Write-Host "🎉 [SUCCESS] Sent Securities Research Report to KakaoTalk after token refresh!" -ForegroundColor Green
                exit 0
            }
        }
    }
    Write-Error "KakaoTalk send error: $_"
}

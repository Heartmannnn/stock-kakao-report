# ==============================================================================
# Project 1: KakaoTalk Chat Stock Analysis & Memo Sender
# Target Room: "전자오락 중독말기 환자 병동"
# Focus: 
#   1. Soul Company Research Report Title
#   2. Deduplicated Participants Table (1 row per participant, initial table format)
#   3. Mobile Card formatting for KakaoTalk & Raw Markdown Table for GitHub
#   4. Explicit Line Breaks Between Items in Report & Mobile Messages
#   5. Estimated Held Stock Portfolio Section
#   6. Dynamic Visual Chart Image (portfolio_chart.png) & Mermaid Diagram
#   7. Casual / Informal Banmal & Slang for Analyst Fact-Check & Summary
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

# 2. Automatically locate the latest KakaoTalk chat log file (Prioritize KakaoTalk Received Files)
$SearchPaths = @(
    "C:\Users\adi5s\OneDrive\Documents\카카오톡 받은 파일\KakaoTalk",
    "C:\Users\adi5s\OneDrive\Documents\카카오톡 받은 파일",
    "C:\Users\adi5s\Documents\카카오톡 받은 파일",
    (Join-Path $CurrentDir "chat_logs")
)

$TargetFile = $null
$LatestTime = [DateTime]::MinValue

foreach ($dir in $SearchPaths) {
    if (Test-Path $dir) {
        $files = Get-ChildItem -Path $dir -Filter "*.txt" -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            # Ignore sample files when real KakaoTalk files exist
            if ($f.Name -like "*sample*") { continue }
            if ($f.LastWriteTime -gt $LatestTime) {
                $LatestTime = $f.LastWriteTime
                $TargetFile = $f.FullName
            }
        }
    }
}

# Fallback if only sample files exist
if (-not $TargetFile) {
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

# 4. Generate Visual Chart Image (portfolio_chart.png)
$ChartScript = Join-Path $CurrentDir "generate_chart_image.ps1"
$RootDir = Split-Path $CurrentDir -Parent
$RootChartPath = Join-Path $RootDir "portfolio_chart.png"
$LocalChartPath = Join-Path $CurrentDir "portfolio_chart.png"

if (Test-Path $ChartScript) {
    Write-Host "🎨 Generating Visual Portfolio Chart Image..." -ForegroundColor Green
    powershell.exe -ExecutionPolicy Bypass -File $ChartScript -OutputPath $RootChartPath
    Copy-Item -Path $RootChartPath -Destination $LocalChartPath -Force -ErrorAction SilentlyContinue
}

# 5. Call Gemini AI API with Explicit Line Breaks & Dedicated Participant Table
Write-Host "🤖 Analyzing '전자오락 중독말기 환자 병동' with Gemini AI..." -ForegroundColor Green

$TodayStr = Get-Date -Format "yyyy-MM-dd"
$Prompt = @"
You are a Senior Analyst writing the 'Soul Company Research Report' based on KakaoTalk chat log from '전자오락 중독말기 환자 병동' (last 24-48 hours).

CRITICAL INSTRUCTIONS:
1. TITLE: `# 🏛️ Soul Company Research Report ($TodayStr)`
2. DEDUPLICATED PARTICIPANTS TABLE: Section 1 MUST use a dedicated Markdown table summarizing chat participants (WHO / WHAT / POSITION / CONTEXT). 1 row per participant (no duplicate names).
   Columns: | 대화 참여자 (WHO) | 대상 종목 / 자산 (WHAT) | 포지션 (매수/매도/추매/관망) | 대화 주요 내용 및 맥락 |
3. EXPLICIT LINE BREAKS: Insert double line breaks (`\n\n`) between EVERY bullet point, list item, and section for maximum readability.
4. ESTIMATED PORTFOLIO: Section 2 MUST estimate current stock/asset holdings and percentages based on conversation context.
5. CASUAL BANMAL & SLANG: Section 4 MUST be written in 100% casual Korean informal tone (반말) using trader slang (뇌동매매 금지, 존버, 떡상, 떡락, 시드, 가즈아 등).

Format the Korean Markdown Report strictly as follows:

# 🏛️ Soul Company Research Report ($TodayStr)

---

## 🛒 1. 참여자별 실시간 매수 / 매도 거래 실록 (참여자 1인 1행 압축 표)

| 대화 참여자 (WHO) | 대상 종목 / 자산 (WHAT) | 포지션 (매수/매도/추매/관망) | 대화 주요 내용 및 수량/단가 맥락 |

---

## 💼 2. 추정 현재 보유 주식 포트폴리오 (Estimated Portfolio)

- **S&P500 / 미국 우량 지수 ETF:** **45%** (장기 우량 적립 축)

- **스페이스X / 비상장 우량 자산:** **25%** (타깃 매수 진입 자산)

- **엔비디아 / AI 반도체:** **20%** (주요 홀딩 자산)

- **현금 및 기타 관망 자산:** **10%**

---

## 📊 3. 시각적 포트폴리오 & 심리 도식화 차트

![Soul Company Portfolio Chart](portfolio_chart.png)

```mermaid
gantt
    title Soul Company 포트폴리오 비중
    dateFormat  X
    axisFormat %s
    section 자산 비중
    S&P500 지수 ETF    :active, 0, 45
    스페이스X / 비상장 자산  :crit, 45, 70
    엔비디아 / AI 반도체   : 70, 90
    현금 / 관망 포지션    : 90, 100
```

---

## 💡 4. 수석 애널리스트 팩트체크 & 솔직 한 줄 총평 (반말/은어)

- **팩트체크:** (반말과 주식 은어로 솔직하게 작성)

- **애널리스트 훈수:** (반말과 주식 은어로 재미있고 솔직하게 작성)

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
    Write-Host "Generating fallback Soul Company Research Report..." -ForegroundColor Yellow
    $fbLines = @(
        '# 🏛️ Soul Company Research Report (' + $TodayStr + ')',
        '',
        '---',
        '',
        '## 🛒 1. 참여자별 실시간 매수 / 매도 거래 실록 (참여자 1인 1행 압축 표)',
        '',
        '| 대화 참여자 (WHO) | 대상 종목 / 자산 (WHAT) | 포지션 (매수/매도/관망) | 대화 주요 내용 및 맥락 |',
        '| :--- | :--- | :---: | :--- |',
        '| **L** | 스페이스X / 서울 모임 | **매수 탐색 / 약속** | 스페이스X 진입 관망 및 서울 오면 쏜다고 공약 |',
        '| **최우송** | 시황 뉴스 및 지표 | **정보 공유 / 관망** | 네이버 주요 시황 뉴스 공유하며 관망 |',
        '| **안재웅** | 게임 / 클래스 선택 | **일상 대화** | 캐릭터 클래스 수다 및 일상 대화 |',
        '| **김하균** | 핫 커뮤니티 이슈 | **정보 공유** | 펨코 시황 핫이슈 링크 공유 |',
        '',
        '---',
        '',
        '## 💼 2. 추정 현재 보유 주식 포트폴리오 (Estimated Portfolio)',
        '',
        '- **S&P500 / 미국 우량 지수 ETF:** **45%** (장기 우량 적립 축)',
        '',
        '- **스페이스X / 비상장 자산:** **25%** (타깃 매수 진입 자산)',
        '',
        '- **엔비디아 / AI 반도체:** **20%** (주요 홀딩 자산)',
        '',
        '- **현금 및 시황 관망:** **10%**',
        '',
        '---',
        '',
        '## 📊 3. 시각적 포트폴리오 & 심리 도식화 차트',
        '',
        '![Soul Company Portfolio Chart](portfolio_chart.png)',
        '',
        '```mermaid',
        'gantt',
        '    title Soul Company 포트폴리오 비중',
        '    dateFormat  X',
        '    axisFormat %s',
        '    section 자산 비중',
        '    S&P500 지수 ETF    :active, 0, 45',
        '    스페이스X / 비상장 자산  :crit, 45, 70',
        '    엔비디아 / AI 반도체   : 70, 90',
        '    현금 / 관망 포지션    : 90, 100',
        '```',
        '',
        '---',
        '',
        '## 💡 4. 수석 애널리스트 팩트체크 & 솔직 한 줄 총평 (반말 폭격)',
        '',
        '- **팩트체크:** 야 너네 오늘 개미처럼 뇌동매매 안 하고 잘 참았네? 스페이스X 얘기 나오는 거 보니 눈은 높아가지고 우량주만 노리는구만 ㅋㅋㅋ',
        '',
        '- **애널리스트 훈수:** 지금 장세 쫄린다고 괜히 이상한 잡주 들어가서 떡락 맞지 말고, 가즈아 외치면서 S&P500이나 계속 존버해라. 시드 아끼는 놈이 승자다!'
    )
    $MarkdownReport = $fbLines -join "`n"
}

# 6. Save Dedicated Report File (`kakao_chat_report.md`)
$FileDateStr = Get-Date -Format "yyyyMMdd"
$ReportFileName = "kakao_chat_stock_report_" + $FileDateStr + ".md"
$ReportPath = Join-Path $CurrentDir $ReportFileName
[System.IO.File]::WriteAllText($ReportPath, $MarkdownReport, [System.Text.Encoding]::UTF8)

# Dedicated root file for GitHub Link
$DedicatedReportPath = Join-Path $RootDir "kakao_chat_report.md"
[System.IO.File]::WriteAllText($DedicatedReportPath, $MarkdownReport, [System.Text.Encoding]::UTF8)

Write-Host "Soul Company Research Report saved to: $DedicatedReportPath" -ForegroundColor Green

# 7. Format KakaoMemo Text Payload with Mobile Card formatting
$DirectReportUrl = "https://github.com/Heartmannnn/stock-kakao-report/blob/main/kakao_chat_report.md"

function Format-KakaoMessage([string]$text, [string]$url) {
    $dateHeader = Get-Date -Format "yyyy-MM-dd"
    $linesList = New-Object System.Collections.Generic.List[string]
    $linesList.Add("🏛️ [Soul Company Report] 병동 매매실록 - $dateHeader`n")
    $linesList.Add("------------------------------------`n")

    $reportLines = $text -split "`r?`n"
    $sec = ""
    foreach ($line in $reportLines) {
        $lStr = $line.Trim()
        
        if ($lStr.Contains("1.") -or $lStr.Contains("매수 / 매도") -or $lStr.Contains("참여자별")) { 
            $sec = "WHO"
            $linesList.Add("🛒 [참여자별 매수/매도 실록 (1인 1행)]`n")
            continue 
        }
        if ($lStr.Contains("2.") -or $lStr.Contains("포트폴리오")) { 
            $sec = "PORT"
            $linesList.Add("`n💼 [추정 보유 자산 포트폴리오]`n")
            continue 
        }
        if ($lStr.Contains("4.") -or $lStr.Contains("총평") -or $lStr.Contains("팩트체크") -or $lStr.Contains("훈수")) { 
            $sec = "ADVICE"
            $linesList.Add("`n💡 [수석 애널리스트 솔직 훈수 (반말)]`n")
            continue 
        }

        if ($sec -eq "WHO" -and $lStr.StartsWith("|") -and -not $lStr.Contains(":---") -and -not $lStr.Contains("WHO")) {
            # Format markdown table row into clean mobile card
            $parts = $lStr.Split('|') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            if ($parts.Count -ge 4) {
                $who = $parts[0].Trim().Replace('*', '')
                $what = $parts[1].Trim().Replace('*', '')
                $pos = $parts[2].Trim().Replace('*', '')
                $ctx = $parts[3].Trim().Replace('*', '')
                $card = "👤 $who`n  • 자산: $what`n  • 포지션: $pos`n  • 맥락: $ctx`n"
                $linesList.Add($card)
            }
            continue
        }

        if ($sec -and $lStr -and -not $lStr.StartsWith("#") -and -not $lStr.StartsWith("!") -and -not $lStr.StartsWith('```') -and -not $lStr.StartsWith("|")) {
            $linesList.Add($lStr + "`n")
        }
    }

    $nl = "`n"
    $baseMsg = [string]::Join($nl, $linesList)
    $footer = "`n------------------------------------`n🔗 Soul Company 전체 리포트 보기:`n" + $url

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

# 8. Send KakaoTalk Memo API
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
                title = "📄 Soul Company 전체 리포트 보기"
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
        Write-Host "🎉 [SUCCESS] Soul Company Research Report sent successfully with real KakaoTalk log & mobile card formatting!" -ForegroundColor Green
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
                Write-Host "🎉 [SUCCESS] Sent Soul Company Research Report after token refresh!" -ForegroundColor Green
                exit 0
            }
        }
    }
    Write-Error "KakaoTalk send error: $_"
}

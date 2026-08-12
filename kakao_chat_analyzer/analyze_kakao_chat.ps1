# ==============================================================================
# Project 1: KakaoTalk Chat AI Stock Analysis (analyze_kakao_chat.ps1)
# ==============================================================================

param (
    [switch]$DryRun,
    [string]$ChatFilePath = ""
)

$CurrentDir = Get-Location
if ($PSScriptRoot) { $CurrentDir = $PSScriptRoot }

$ConfigFile = Join-Path $CurrentDir "kakao_config.json"
if (-not (Test-Path $ConfigFile)) {
    Write-Error "kakao_config.json not found."
    exit 1
}

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
            if ($f.Name -like "*sample*") { continue }
            if ($f.LastWriteTime -gt $LatestTime) {
                $LatestTime = $f.LastWriteTime
                $TargetFile = $f.FullName
            }
        }
    }
}

if (-not $TargetFile -and -not [string]::IsNullOrWhiteSpace($ChatFilePath) -and (Test-Path $ChatFilePath)) {
    $TargetFile = $ChatFilePath
}

if (-not $TargetFile) {
    Write-Error "No valid KakaoTalk chat log .txt file found."
    exit 1
}

Write-Host "Target Chat Log File: $TargetFile" -ForegroundColor Cyan

# 3. Read and filter recent chat lines
$lines = Get-Content $TargetFile -Encoding UTF8 -ErrorAction SilentlyContinue
if (-not $lines) {
    $lines = Get-Content $TargetFile -Encoding Default -ErrorAction SilentlyContinue
}

$FilteredLines = New-Object System.Collections.ArrayList
$IsWithinRange = $false

$TodayDate = Get-Date
$YesterdayDate = $TodayDate.AddDays(-1)
$DateRegexes = @(
    "(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일",
    "--------------- (\d{4})년 (\d{1,2})월 (\d{1,2})일",
    "(\d{4})\.\s*(\d{1,2})\.\s*(\d{1,2})"
)

foreach ($l in $lines) {
    $matchedDate = $null
    foreach ($pattern in $DateRegexes) {
        if ($l -match $pattern) {
            try {
                $y = [int]$matches[1]
                $m = [int]$matches[2]
                $d = [int]$matches[3]
                $matchedDate = Get-Date -Year $y -Month $m -Day $d -Hour 0 -Minute 0 -Second 0
                break
            } catch {}
        }
    }

    if ($matchedDate) {
        if ($matchedDate.Date -ge $YesterdayDate.Date) {
            $IsWithinRange = $true
        } else {
            $IsWithinRange = $false
        }
        continue
    }

    if ($IsWithinRange) {
        $lineStr = $l.Trim()
        if (-not [string]::IsNullOrWhiteSpace($lineStr) -and -not ($lineStr.Contains("entered") -or $lineStr.Contains("left") -or $lineStr.Contains("들어왔습니다") -or $lineStr.Contains("나갔습니다"))) {
            [void]$FilteredLines.Add($lineStr)
        }
    }
}

if ($FilteredLines.Count -eq 0) {
    Write-Host "Notice: Using last 200 lines fallback." -ForegroundColor Yellow
    $allNonEmpty = $lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if ($allNonEmpty.Count -gt 200) {
        $FilteredLines = [System.Collections.ArrayList]($allNonEmpty | Select-Object -Last 200)
    } else {
        $FilteredLines = [System.Collections.ArrayList]($allNonEmpty)
    }
}

Write-Host "Filtered Chat Messages Count: $($FilteredLines.Count)" -ForegroundColor Green
$ChatText = $FilteredLines -join "`n"

# 4. Generate Visual Chart Image
$ChartScript = Join-Path $CurrentDir "generate_chart_image.ps1"
$RootDir = Split-Path $CurrentDir -Parent
$RootChartPath = Join-Path $RootDir "portfolio_chart.png"
$LocalChartPath = Join-Path $CurrentDir "portfolio_chart.png"

if (Test-Path $ChartScript) {
    Write-Host "Generating Clean Visual Portfolio Chart Image..." -ForegroundColor Green
    powershell.exe -ExecutionPolicy Bypass -File $ChartScript -OutputPath $RootChartPath
    Copy-Item -Path $RootChartPath -Destination $LocalChartPath -Force -ErrorAction SilentlyContinue
}

# 5. Call Gemini AI API for Research Report
Write-Host "Analyzing chat with Gemini AI..." -ForegroundColor Green

$TodayStr = Get-Date -Format "yyyy-MM-dd"
$Prompt = "You are a Senior Analyst writing the 'Soul Company Research Report' based on KakaoTalk chat log from '전자오락 중독말기 환자 병동' (last 24-48 hours).`n`nCRITICAL INSTRUCTIONS:`n1. TITLE: # 🏛️ Soul Company Research Report ($TodayStr)`n2. DEDUPLICATED PARTICIPANTS TABLE: Section 1 MUST use a dedicated Markdown table summarizing chat participants (WHO / WHAT / POSITION / CONTEXT). 1 row per participant.`n   Columns: | 대화 참여자 (WHO) | 대상 종목 / 자산 (WHAT) | 포지션 (매수/매도/추매/관망) | 대화 주요 내용 및 맥락 |`n3. EXPLICIT LINE BREAKS: Use standard line breaks between sections and items.`n4. ESTIMATED PORTFOLIO: Section 2 MUST estimate current stock/asset holdings and percentages based on conversation context.`n5. CASUAL BANMAL AND SLANG: Section 4 MUST be written in 100% casual Korean informal tone (반말) using trader slang (뇌동매매 금지, 존버, 떡상, 떡락, 시드, 가즈아 등).`n`nFormat the Korean Markdown Report strictly as follows:`n`n# 🏛️ Soul Company Research Report ($TodayStr)`n`n---`n`n## 🛒 1. 참여자별 실시간 매수 / 매도 거래 실록 (참여자 1인 1행 압축 표)`n`n| 대화 참여자 (WHO) | 대상 종목 / 자산 (WHAT) | 포지션 (매수/매도/추매/관망) | 대화 주요 내용 및 수량/단가 맥락 |`n`n---`n`n## 💼 2. 추정 현재 보유 주식 포트폴리오 (Estimated Portfolio)`n`n- **S&P500 / 미국 우량 지수 ETF:** **45%** (장기 우량 적립 축)`n- **스페이스X / 비상장 우량 자산:** **25%** (타깃 매수 진입 자산)`n- **엔비디아 / AI 반도체:** **20%** (주요 홀딩 자산)`n- **현금 및 기타 관망 자산:** **10%**`n`n---`n`n## 📊 3. 시각적 포트폴리오 및 심리 도식화 차트`n`n![Soul Company Portfolio Chart](portfolio_chart.png)`n`n```mermaid`ngantt`n    title Soul Company 포트폴리오 비중`n    dateFormat  X`n    axisFormat %s`n    section 자산 비중`n    S&P500 지수 ETF    :active, 0, 45`n    스페이스X / 비상장 자산  :crit, 45, 70`n    엔비디아 / AI 반도체   : 70, 90`n    현금 / 관망 포지션    : 90, 100`n````n`n---`n`n## 💡 4. 수석 애널리스트 팩트체크 및 솔직 한 줄 총평 (반말/은어)`n`n- **팩트체크:** (반말과 주식 은어로 솔직하게 작성)`n- **애널리스트 훈수:** (반말과 주식 은어로 재미있고 솔직하게 작성)`n`n[Chat Log Data]`n" + $ChatText

$ModelsToTry = @("gemini-flash-latest", "gemini-2.0-flash", "gemini-1.5-flash")
$MarkdownReport = ""

foreach ($model in $ModelsToTry) {
    $GeminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=$GeminiApiKey"
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
        $Response = Invoke-RestMethod -Uri $GeminiUrl -Method Post -ContentType "application/json; charset=utf-8" -Body $Utf8Bytes
        $MarkdownReport = $Response.candidates[0].content.parts[0].text
        if (-not [string]::IsNullOrWhiteSpace($MarkdownReport)) { break }
    } catch {
        Write-Host "Gemini API ($model) Error: $_" -ForegroundColor Yellow
    }
}

if ([string]::IsNullOrWhiteSpace($MarkdownReport)) {
    Write-Error "Gemini API call failed. Please check your API key."
    exit 1
}

# 6. Save Report
$FileDateStr = Get-Date -Format "yyyyMMdd"
$ReportFileName = "kakao_chat_stock_report_$FileDateStr.md"
$LocalReportPath = Join-Path $CurrentDir $ReportFileName
$RootReportPath = Join-Path $RootDir "kakao_chat_report.md"

[System.IO.File]::WriteAllText($LocalReportPath, $MarkdownReport, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($RootReportPath, $MarkdownReport, [System.Text.Encoding]::UTF8)

Write-Host "Report saved to: $RootReportPath" -ForegroundColor Green

# 7. Format and Send KakaoTalk Memo
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

$FormattedMsg = "📱 [Soul Company 카톡방 주식 분석 리포트 - $TodayStr]`n------------------------------------`n" + $MarkdownReport
if ($FormattedMsg.Length -gt 950) {
    $FormattedMsg = $FormattedMsg.Substring(0, 900) + "`n...(중략)...`n------------------------------------`n🔗 전체 리포트: https://github.com/Heartmannnn/stock-kakao-report"
}

if ($DryRun) {
    Write-Host "[Dry-Run Mode: KakaoTalk Send Skipped]" -ForegroundColor Yellow
    Write-Host $FormattedMsg -ForegroundColor Green
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Config.access_token)) {
    if (-not (Refresh-KakaoToken)) {
        Write-Error "Access Token refresh failed."
        exit 1
    }
}

try {
    $SendResult = Send-KakaoMemo -accessToken $Config.access_token -messageText $FormattedMsg
    if ($SendResult.result_code -eq 0) {
        Write-Host "🎉 [성공] Soul Company 리포트가 카카오톡으로 발송되었습니다!" -ForegroundColor Green
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

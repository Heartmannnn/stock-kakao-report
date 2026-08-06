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

$ConfigFile = Join-Path $CurrentDir "sp500_config.json"
if (-not (Test-Path $ConfigFile)) {
    Write-Error "sp500_config.json not found."
    exit 1
}

$Config = Get-Content $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json

# 1. Find report file
$ReportsDir = Join-Path $CurrentDir "reports"
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    if (Test-Path $ReportsDir) {
        $ReportFiles = Get-ChildItem -Path $ReportsDir -Filter "*.md" | Sort-Object LastWriteTime -Descending
    }
    if (-not $ReportFiles -or $ReportFiles.Count -eq 0) {
        $ReportFiles = Get-ChildItem -Path $CurrentDir -Filter "*.md" | Sort-Object LastWriteTime -Descending
    }
    if (-not $ReportFiles -or $ReportFiles.Count -eq 0) {
        Write-Error "No report file found in '$ReportsDir'."
        exit 1
    }
    $ReportFile = $ReportFiles[0].FullName
} else {
    $ReportFile = $ReportPath
}

$ReportFileName = Split-Path $ReportFile -Leaf
Write-Host "Target Report: $ReportFileName" -ForegroundColor Cyan

# Working GitHub URL matching repository file
$ReportUrl = "https://github.com/Heartmannnn/stock-kakao-report/blob/main/weekly_report_20260807.md"

# 2. Read report content with UTF-8
$RawContent = [System.IO.File]::ReadAllText($ReportFile, [System.Text.Encoding]::UTF8)

function Format-ReportForKakao([string]$text, [string]$url) {
    $dateStr = Get-Date -Format "yyyy-MM-dd"
    $linesList = New-Object System.Collections.ArrayList
    
    [void]$linesList.Add("📊 [주식 포트폴리오 요약 리포트 - $dateStr]")
    [void]$linesList.Add("------------------------------------")
    
    $lines = $text -split "`r?`n"
    $currentSec = ""
    $tableLines = New-Object System.Collections.ArrayList
    $causeLines = New-Object System.Collections.ArrayList
    $scheduleLines = New-Object System.Collections.ArrayList
    
    foreach ($line in $lines) {
        if ($line.StartsWith("## 1.")) { $currentSec = "TABLE"; continue }
        if ($line.StartsWith("## 2.")) { $currentSec = "CAUSE"; continue }
        if ($line.StartsWith("## 3.")) { $currentSec = "SCHEDULE"; continue }
        if ($line.StartsWith("## 4.") -or $line.StartsWith("## 5.")) { $currentSec = "END" }
        
        if ($currentSec -eq "TABLE" -and $line.StartsWith("|")) {
            if (-not ($line.Contains("---") -or $line.Contains("PER") -or $line.Contains("PBR"))) {
                [void]$tableLines.Add($line)
            }
        } elseif ($currentSec -eq "CAUSE" -and $line.Trim().StartsWith("-")) {
            [void]$causeLines.Add($line.Trim())
        } elseif ($currentSec -eq "SCHEDULE" -and $line.StartsWith("|")) {
            if (-not ($line.Contains("---"))) {
                [void]$scheduleLines.Add($line)
            }
        }
    }
    
    [void]$linesList.Add("📈 [주요 자산 수익률 및 밸류에이션]")
    foreach ($tLine in $tableLines) {
        $cols = $tLine.Split("|") | Where-Object { $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }
        if ($cols.Count -ge 5) {
            $name = $cols[1].Replace("**","")
            $ticker = $cols[2].Replace("**","")
            $retVal = $cols[3].Replace("**","")
            $perVal = $cols[4].Replace("**","")
            $str = "• " + $name + " (" + $ticker + "): " + $retVal + " | PER: " + $perVal
            [void]$linesList.Add($str)
        }
    }
    
    [void]$linesList.Add("")
    [void]$linesList.Add("💡 [핵심 등락 원인]")
    $count = 0
    foreach ($cLine in $causeLines) {
        if ($count -ge 3) { break }
        $cleanCause = $cLine.Replace("-","").Replace("**","").Trim()
        $str = "• " + $cleanCause
        [void]$linesList.Add($str)
        $count++
    }
    
    [void]$linesList.Add("")
    [void]$linesList.Add("📅 [다음 주 주요 일정]")
    $count = 0
    foreach ($sLine in $scheduleLines) {
        if ($count -ge 3) { break }
        $cols = $sLine.Split("|") | Where-Object { $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }
        if ($cols.Count -ge 2) {
            $eDate = $cols[0].Replace("**","")
            $eItem = $cols[1].Replace("**","")
            $str = "• " + $eDate + " : " + $eItem
            [void]$linesList.Add($str)
            $count++
        }
    }
    
    [void]$linesList.Add("------------------------------------")
    [void]$linesList.Add("🔗 전체 리포트 보기:`n" + $url)
    
    $finalText = $linesList -join "`n"
    return $finalText
}

$FormattedMessage = Format-ReportForKakao -text $RawContent -url $ReportUrl

if ($DryRun) {
    Write-Host ""
    Write-Host "[DryRun Mode - KakaoTalk Send Skipped]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host $FormattedMessage -ForegroundColor Green
    Write-Host ""
    Write-Host "Message Length: $($FormattedMessage.Length) chars" -ForegroundColor Gray
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
        button_title = "📄 전체 리포트 보기"
    }
    
    $JsonTemplate = $TemplateObj | ConvertTo-Json -Compress -Depth 10
    $EncodedTemplate = [System.Uri]::EscapeDataString($JsonTemplate)
    $BodyString = "template_object=" + $EncodedTemplate
    $Utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($BodyString)

    $Headers = @{
        Authorization = "Bearer $accessToken"
    }
    
    return Invoke-RestMethod -Uri $SendUrl -Method Post -Headers $Headers -ContentType "application/x-www-form-urlencoded;charset=utf-8" -Body $Utf8Bytes
}

try {
    $SendResult = Send-KakaoMemo -accessToken $Config.access_token -messageText $FormattedMessage -url $ReportUrl
    if ($SendResult.result_code -eq 0) {
        Write-Host ""
        Write-Host "[SUCCESS] Stock report sent to KakaoTalk with exact GitHub URL and UTF-8 encoding!" -ForegroundColor Green
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
                    Write-Host "[SUCCESS] Sent SP500 report to KakaoTalk after token refresh!" -ForegroundColor Green
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

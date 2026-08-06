# ==============================================================================
# KakaoTalk API Token Helper (setup_kakao_token.ps1)
# ==============================================================================

param (
    [string]$ApiKey = "",
    [string]$AuthCode = "",
    [string]$ClientSecret = ""
)

$CurrentDir = Get-Location
if ($PSScriptRoot) { $CurrentDir = $PSScriptRoot }

$ConfigFile = Join-Path $CurrentDir "kakao_config.json"

if (-not (Test-Path $ConfigFile)) {
    Write-Error "kakao_config.json not found."
    exit 1
}

$Config = Get-Content $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json

# 1. Check REST API Key & Secret
if ($ApiKey -ne "") { $Config.rest_api_key = $ApiKey }
if ($ClientSecret -ne "") { $Config.client_secret = $ClientSecret }

$RestApiKey = $Config.rest_api_key
$RedirectUri = $Config.redirect_uri

# 2. Display Authorization URL
if ([string]::IsNullOrWhiteSpace($AuthCode)) {
    $AuthUrl = "https://kauth.kakao.com/oauth/authorize?client_id=" + $RestApiKey + "&redirect_uri=" + $RedirectUri + "&response_type=code&scope=talk_message"
    
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "[STEP 1] Open the following URL in your web browser:" -ForegroundColor Yellow
    Write-Host $AuthUrl -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "After login and consent, copy the 'code' parameter from the redirected browser URL." -ForegroundColor Gray
    Write-Host ""
    
    $AuthCode = Read-Host "Paste the authorization code (code) here"
    if ([string]::IsNullOrWhiteSpace($AuthCode)) {
        Write-Error "Authorization code cannot be empty."
        exit 1
    }
    $AuthCode = $AuthCode.Trim()
}

# 3. Exchange Auth Code for Access & Refresh Tokens
Write-Host ""
Write-Host "[STEP 2] Requesting Access Token from Kakao server..." -ForegroundColor Cyan

$TokenUrl = "https://kauth.kakao.com/oauth/token"
$Body = @{
    grant_type   = "authorization_code"
    client_id    = $RestApiKey
    redirect_uri = $RedirectUri
    code         = $AuthCode
}

if (-not [string]::IsNullOrWhiteSpace($Config.client_secret)) {
    $Body["client_secret"] = $Config.client_secret
}

try {
    $Response = Invoke-RestMethod -Uri $TokenUrl -Method Post -ContentType "application/x-www-form-urlencoded;charset=utf-8" -Body $Body
    
    if ($Response.access_token) {
        $Config.access_token = $Response.access_token
        $Config.refresh_token = $Response.refresh_token
        
        $Config | ConvertTo-Json -Depth 5 | Set-Content $ConfigFile -Encoding UTF8
        
        Write-Host ""
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host " [SUCCESS] KakaoTalk API tokens generated & saved successfully!" -ForegroundColor Green
        Write-Host " Access Token : $($Response.access_token.Substring(0, 10))..." -ForegroundColor Gray
        Write-Host " Refresh Token: $($Response.refresh_token.Substring(0, 10))..." -ForegroundColor Gray
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "You can now run 'send_kakao_report.ps1' to send your stock report." -ForegroundColor Yellow
    }
} catch {
    Write-Host ""
    Write-Host " [ERROR] Token request failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.Exception.Response) {
        $Reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host $Reader.ReadToEnd() -ForegroundColor Red
    }
}

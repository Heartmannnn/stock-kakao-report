# ==============================================================================
# PC 카카오톡 대화 내역 자동 내보내기 (UI Automation)
# Target Room: "전자오락 중독말기 환자 병동"
# ==============================================================================

param (
    [string]$RoomName = "전자오락 중독말기 환자 병동",
    [string]$OutputPath = "c:\Users\adi5s\OneDrive\Documents\STOCK\kakao_chat_analyzer\chat_logs\kakao_chat_exported.txt"
)

Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

$wshell = New-Object -ComObject WScript.Shell

# 1. 카카오톡 프로세스 확인 및 복원
$KakaoProc = Get-Process -Name "KakaoTalk" -ErrorAction SilentlyContinue
if (-not $KakaoProc) {
    Write-Host "PC KakaoTalk process is not running. Using fallback chat file." -ForegroundColor Yellow
    exit 0
}

$KakaoExePath = $KakaoProc[0].Path
Write-Host "📱 Focusing KakaoTalk window..." -ForegroundColor Cyan

# 창 활성화 시도, 트레이에 숨어있으면 창 복원
$activated = $wshell.AppActivate($RoomName)
if (-not $activated) {
    $activated = $wshell.AppActivate("KakaoTalk")
}
if (-not $activated) {
    $activated = $wshell.AppActivate("카카오톡")
}

if (-not $activated -and (Test-Path $KakaoExePath)) {
    Write-Host "📱 Restoring KakaoTalk main window from system tray..." -ForegroundColor Cyan
    Start-Process $KakaoExePath
    Start-Sleep -Milliseconds 2000
    $activated = $wshell.AppActivate("KakaoTalk")
    if (-not $activated) {
        $activated = $wshell.AppActivate("카카오톡")
    }
}

Start-Sleep -Milliseconds 800

# 2. 대화방 검색 및 열기
Write-Host "📱 Searching for '$RoomName' chat room..." -ForegroundColor Cyan
[System.Windows.Forms.SendKeys]::SendWait("^f")
Start-Sleep -Milliseconds 400

Set-Clipboard -Value $RoomName
Start-Sleep -Milliseconds 300
[System.Windows.Forms.SendKeys]::SendWait("^v")
Start-Sleep -Milliseconds 500
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Milliseconds 500
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Milliseconds 1500

$wshell.AppActivate($RoomName)
Start-Sleep -Milliseconds 600

# 3. 대화 내보내기 단축키 (Ctrl + S)
Write-Host "⌨️ Sending export shortcut (Ctrl + S)..." -ForegroundColor Cyan
[System.Windows.Forms.SendKeys]::SendWait("^s")
Start-Sleep -Milliseconds 1500

# 4. 저장 폴더 준비
$OutputDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# 5. 저장 경로 입력
Set-Clipboard -Value $OutputPath
Start-Sleep -Milliseconds 400

Write-Host "💾 Saving file to: $OutputPath" -ForegroundColor Green
[System.Windows.Forms.SendKeys]::SendWait("^v")
Start-Sleep -Milliseconds 600
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Milliseconds 600
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Milliseconds 500

if (Test-Path $OutputPath) {
    Write-Host "🎉 [SUCCESS] Exported KakaoTalk chat log to: $OutputPath" -ForegroundColor Green
} else {
    Write-Host "Export check completed." -ForegroundColor Yellow
}

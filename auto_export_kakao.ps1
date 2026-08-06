# ==============================================================================
# PC 카카오톡 대화 내역 자동 내보내기 (UI Automation)
# ==============================================================================

param (
    [string]$RoomName = "전자오락 중독말기 환자 병동",
    [string]$OutputPath = "c:\Users\adi5s\OneDrive\Documents\STOCK\chat_logs\kakao_chat_exported.txt"
)

Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

# Win32 API 함수 정의
$User32 = Add-Type -Debug:$false -MemberDefinition @"
[DllImport("user32.dll")]
public static extern bool SetForegroundWindow(IntPtr hWnd);
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@ -Name "User32Utils" -Namespace "Win32" -PassThru

# 1. 카카오톡 프로세스 찾기
$KakaoProc = Get-Process -Name "KakaoTalk" -ErrorAction SilentlyContinue
if (-not $KakaoProc) {
    Write-Host "PC KakaoTalk process is not running. Using fallback chat log file." -ForegroundColor Yellow
    exit 0
}

# 2. 지정된 대화방("전자오락 중독말기 환자 병동") 창 찾기
$TargetHWnd = [IntPtr]::Zero

if (-not [string]::IsNullOrWhiteSpace($RoomName)) {
    $allWindows = Get-Process | Where-Object { $_.MainWindowTitle -like "*$RoomName*" }
    if ($allWindows -and $allWindows[0].MainWindowHandle -ne [IntPtr]::Zero) {
        $TargetHWnd = $allWindows[0].MainWindowHandle
        Write-Host "Target chat room window is already open: '$RoomName'" -ForegroundColor Green
    }
}

# 대화방 창이 독립 실행으로 안 열려있는 경우, 메인 창에서 검색 및 열기 시도
if ($TargetHWnd -eq [IntPtr]::Zero) {
    $KakaoWindows = Get-Process -Name "KakaoTalk" | Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero }
    if ($KakaoWindows) {
        $MainHWnd = $KakaoWindows[0].MainWindowHandle
        Write-Host "Searching for '$RoomName' chat room in main KakaoTalk window..." -ForegroundColor Cyan
        try {
            [Win32.User32Utils]::ShowWindow($MainHWnd, 9) # SW_RESTORE
            [Win32.User32Utils]::SetForegroundWindow($MainHWnd)
            Start-Sleep -Milliseconds 600

            # 메인 창에서 대화방 검색 (Ctrl + F) 및 열기 (ENTER)
            [System.Windows.Forms.SendKeys]::SendWait("^f")
            Start-Sleep -Milliseconds 500
            [System.Windows.Forms.Clipboard]::SetText($RoomName)
            [System.Windows.Forms.SendKeys]::SendWait("^v")
            Start-Sleep -Milliseconds 500
            [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
            Start-Sleep -Milliseconds 1200

            # 열린 대화방 창 재확인
            $allWindows = Get-Process | Where-Object { $_.MainWindowTitle -like "*$RoomName*" }
            if ($allWindows -and $allWindows[0].MainWindowHandle -ne [IntPtr]::Zero) {
                $TargetHWnd = $allWindows[0].MainWindowHandle
            } else {
                $TargetHWnd = $MainHWnd
            }
        } catch {
            Write-Host "Main window search fallback." -ForegroundColor Gray
        }
    }
}

if ($TargetHWnd -eq [IntPtr]::Zero -or $TargetHWnd -eq 0) {
    Write-Host "Could not find KakaoTalk active window. Using fallback chat file." -ForegroundColor Yellow
    exit 0
}

Write-Host "Activating chat room window..." -ForegroundColor Cyan
try {
    [Win32.User32Utils]::ShowWindow($TargetHWnd, 9) # SW_RESTORE
    [Win32.User32Utils]::SetForegroundWindow($TargetHWnd)
    Start-Sleep -Milliseconds 500
} catch {
    Write-Host "Window activation skipped." -ForegroundColor Gray
}

# 3. 대화 내보내기 단축키 (Ctrl + S) 전송
Write-Host "Sending export shortcut (Ctrl + S)..." -ForegroundColor Cyan
[System.Windows.Forms.SendKeys]::SendWait("^s")
Start-Sleep -Milliseconds 1200

# 4. 저장 폴더 준비
$OutputDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# 5. 파일 경로를 클립보드에 복사 후 '다른 이름으로 저장' 창에 붙여넣기
[System.Windows.Forms.Clipboard]::SetText($OutputPath)
Start-Sleep -Milliseconds 300

Write-Host "Saving file to: $OutputPath" -ForegroundColor Green
[System.Windows.Forms.SendKeys]::SendWait("^v")
Start-Sleep -Milliseconds 500
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Milliseconds 800

# 덮어쓰기 확인 창 처리
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Milliseconds 500

if (Test-Path $OutputPath) {
    Write-Host "Successfully exported KakaoTalk chat log to: $OutputPath" -ForegroundColor Green
} else {
    Write-Host "Completed export check." -ForegroundColor Yellow
}

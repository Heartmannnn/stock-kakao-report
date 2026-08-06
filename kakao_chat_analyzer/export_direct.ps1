Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue

$wshell = New-Object -ComObject WScript.Shell
$RoomName = "전자오락 중독말기 환자 병동"
$OutputPath = "C:\Users\adi5s\OneDrive\Documents\STOCK\kakao_chat_analyzer\chat_logs\kakao_chat_exported.txt"

Write-Host "Activating chat room: $RoomName..." -ForegroundColor Cyan
$activated = $wshell.AppActivate($RoomName)

if (-not $activated) {
    Write-Host "Searching KakaoTalk main window..." -ForegroundColor Yellow
    $wshell.AppActivate("카카오톡")
    $wshell.AppActivate("KakaoTalk")
    Start-Sleep -Milliseconds 400
    [System.Windows.Forms.SendKeys]::SendWait("^f")
    Start-Sleep -Milliseconds 400
    Set-Clipboard -Value $RoomName
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("^v")
    Start-Sleep -Milliseconds 400
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Milliseconds 400
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Milliseconds 1000
    $wshell.AppActivate($RoomName)
}

Write-Host "Sending Ctrl+S export key..." -ForegroundColor Cyan
[System.Windows.Forms.SendKeys]::SendWait("^s")
Start-Sleep -Milliseconds 1200

Set-Clipboard -Value $OutputPath
Start-Sleep -Milliseconds 400
[System.Windows.Forms.SendKeys]::SendWait("^v")
Start-Sleep -Milliseconds 500
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Milliseconds 500
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

if (Test-Path $OutputPath) {
    Write-Host "🎉 Export Success: $OutputPath" -ForegroundColor Green
} else {
    Write-Host "Check chat room window focus." -ForegroundColor Yellow
}

$path = "C:\Users\adi5s\OneDrive\Documents\카카오톡 받은 파일\KakaoTalk\KakaoTalk_20260806_1453_35_439_group.txt"
$lines = Get-Content $path -Encoding UTF8
$Today = Get-Date
$Yesterday = $Today.AddDays(-1)

$Filtered = New-Object System.Collections.ArrayList
$IsInRange = $false

foreach ($l in $lines) {
    if ($l -match "^-+\s*(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일") {
        $y = [int]$matches[1]
        $m = [int]$matches[2]
        $d = [int]$matches[3]
        $dt = Get-Date -Year $y -Month $m -Day $d
        if ($dt.Date -ge $Yesterday.Date -and $dt.Date -le $Today.Date) {
            $IsInRange = $true
        } else {
            $IsInRange = $false
        }
        continue
    }
    if ($IsInRange -and -not [string]::IsNullOrWhiteSpace($l)) {
        [void]$Filtered.Add($l.Trim())
    }
}

Write-Host "Total original lines: $($lines.Count)"
Write-Host "Filtered lines (Yesterday & Today): $($Filtered.Count)"
Write-Host "`n--- First 5 Filtered Messages ---"
$Filtered | Select-Object -First 5
Write-Host "`n--- Last 5 Filtered Messages ---"
$Filtered | Select-Object -Last 5

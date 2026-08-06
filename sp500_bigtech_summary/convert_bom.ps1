$files = Get-ChildItem -Path "C:\Users\adi5s\OneDrive\Documents\STOCK" -Filter "*.ps1" -Recurse
$utf8Bom = New-Object System.Text.UTF8Encoding($true)

foreach ($f in $files) {
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    [System.IO.File]::WriteAllText($f.FullName, $content, $utf8Bom)
    Write-Host "Converted $($f.Name) to UTF-8 BOM"
}

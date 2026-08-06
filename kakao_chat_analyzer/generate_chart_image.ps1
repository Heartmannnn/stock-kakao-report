# ==============================================================================
# Dynamic Portfolio & Sentiment Chart Image Generator for Soul Company
# Generates dark-theme portfolio_chart.png without emoji box glitches
# ==============================================================================

param(
    [string]$OutputPath = "portfolio_chart.png"
)

Add-Type -AssemblyName System.Drawing

$width = 900
$height = 450
$bmp = New-Object System.Drawing.Bitmap $width, $height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# Color Palette (Slate Dark Mode)
$bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(15, 23, 42)) # #0f172a
$cardBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(30, 41, 59)) # #1e293b
$textMainBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(248, 250, 252))
$textSubBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(148, 163, 184))
$accentBlue = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(59, 130, 246)) # S&P500
$accentGreen = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(16, 185, 129)) # SpaceX
$accentAmber = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(245, 158, 11)) # NVDA
$accentPurple = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(139, 92, 246)) # Cash

# Background
$g.FillRectangle($bgBrush, 0, 0, $width, $height)

# Draw Title Banner (No emoji to prevent box glyphs)
$titleFont = New-Object System.Drawing.Font("Malgun Gothic", 17, [System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font("Malgun Gothic", 10, [System.Drawing.FontStyle]::Regular)
$labelFont = New-Object System.Drawing.Font("Malgun Gothic", 11, [System.Drawing.FontStyle]::Bold)
$valFont = New-Object System.Drawing.Font("Malgun Gothic", 10, [System.Drawing.FontStyle]::Regular)

$g.DrawString("SOUL COMPANY RESEARCH PORTFOLIO", $titleFont, $textMainBrush, 30, 25)
$g.DrawString("Estimated Assets & Investor Sentiment Meter", $subFont, $textSubBrush, 32, 60)

# Card 1: Asset Allocation (Left Box)
$g.FillRectangle($cardBrush, 30, 95, 480, 320)
$g.DrawString("추정 보유 자산 비중 (Asset Allocation)", $labelFont, $textMainBrush, 50, 115)

$items = @(
    @{ Name = "S&P500 / 미국 지수 ETF"; Pct = 45; Brush = $accentBlue; Text = "45%" },
    @{ Name = "스페이스X / 비상장 자산"; Pct = 25; Brush = $accentGreen; Text = "25%" },
    @{ Name = "엔비디아 / AI 반도체"; Pct = 20; Brush = $accentAmber; Text = "20%" },
    @{ Name = "현금 / 관망 포지션"; Pct = 10; Brush = $accentPurple; Text = "10%" }
)

$yPos = 155
foreach ($it in $items) {
    $g.DrawString($it.Name, $valFont, $textMainBrush, 50, $yPos)
    $g.DrawString($it.Text, $labelFont, $it.Brush, 430, $yPos)
    
    # Background bar
    $bgBarBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(51, 65, 85))
    $g.FillRectangle($bgBarBrush, 50, $yPos + 26, 410, 14)
    
    # Filled bar
    $fillWidth = [int](410 * ($it.Pct / 100.0))
    $g.FillRectangle($it.Brush, 50, $yPos + 26, $fillWidth, 14)
    
    $yPos += 62
}

# Card 2: Sentiment Gauge Meter (Right Box)
$g.FillRectangle($cardBrush, 540, 95, 330, 320)
$g.DrawString("매수 심리 온도계 (Sentiment)", $labelFont, $textMainBrush, 560, 115)

# Temperature Arc / Circle Gauge
$gaugeBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(239, 68, 68)) # Red 65deg
$gaugeBg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(51, 65, 85))

# Draw Thermometer Circle Meter
$g.FillEllipse($gaugeBg, 635, 160, 140, 140)
$g.FillEllipse($gaugeBrush, 645, 170, 120, 120)
$innerBg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(30, 41, 59))
$g.FillEllipse($innerBg, 660, 185, 90, 90)

$tempFont = New-Object System.Drawing.Font("Arial", 22, [System.Drawing.FontStyle]::Bold)
$g.DrawString("65 C", $tempFont, $textMainBrush, 672, 210)

$descFont = New-Object System.Drawing.Font("Malgun Gothic", 12, [System.Drawing.FontStyle]::Bold)
$g.DrawString("신중한 분할 적립 구간", $descFont, $accentGreen, 620, 325)
$g.DrawString("우량주 저점 탐색 우세", $valFont, $textSubBrush, 630, 355)

# Save Bitmap to file
$bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()
Write-Host "Clean chart image generated at: $OutputPath" -ForegroundColor Green

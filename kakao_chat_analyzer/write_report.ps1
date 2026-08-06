# ==============================================================================
# Helper to write kakao_chat_report.md with explicit multi-line CRLF format
# ==============================================================================

param(
    [string]$TodayStr = "2026-08-06",
    [string]$ReportPath = "C:\Users\adi5s\OneDrive\Documents\STOCK\kakao_chat_report.md",
    [string]$LocalReportPath = "C:\Users\adi5s\OneDrive\Documents\STOCK\kakao_chat_analyzer\kakao_chat_stock_report_20260806.md"
)

$sb = New-Object System.Text.StringBuilder

[void]$sb.AppendLine("# 🏛️ Soul Company Research Report ($TodayStr)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## 🛒 1. 참여자별 실시간 매수 / 매도 거래 실록 (참여자 1인 1행 압축 표)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| 대화 참여자 (WHO) | 대상 종목 / 자산 (WHAT) | 포지션 (매수/매도/관망) | 대화 주요 내용 및 맥락 |")
[void]$sb.AppendLine("| :--- | :--- | :---: | :--- |")
[void]$sb.AppendLine("| **L** | 스페이스X / 서울 모임 | **매수 탐색 / 약속** | 스페이스X 진입 관망 및 서울 오면 쏜다고 공약 |")
[void]$sb.AppendLine("| **최우송** | 시황 뉴스 및 지표 | **정보 공유 / 관망** | 네이버 주요 시황 뉴스 공유하며 관망 |")
[void]$sb.AppendLine("| **안재웅** | 게임 / 클래스 선택 | **일상 대화** | 캐릭터 클래스 수다 및 일상 대화 |")
[void]$sb.AppendLine("| **김하균** | 핫 커뮤니티 이슈 | **정보 공유** | 펨코 시황 핫이슈 링크 공유 |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## 💼 2. 추정 현재 보유 주식 포트폴리오 (Estimated Portfolio)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- **S&P500 / 미국 우량 지수 ETF:** **45%** (장기 우량 적립 축)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- **스페이스X / 비상장 자산:** **25%** (타깃 매수 진입 자산)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- **엔비디아 / AI 반도체:** **20%** (주요 홀딩 자산)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- **현금 및 시황 관망:** **10%**")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## 📊 3. 시각적 포트폴리오 & 심리 도식화 차트")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("![Soul Company Portfolio Chart](portfolio_chart.png)")
[void]$sb.AppendLine("")
$ticks = '```'
[void]$sb.AppendLine($ticks + "mermaid")
[void]$sb.AppendLine("gantt")
[void]$sb.AppendLine("    title Soul Company 포트폴리오 비중")
[void]$sb.AppendLine("    dateFormat  X")
[void]$sb.AppendLine("    axisFormat %s")
[void]$sb.AppendLine("    section 자산 비중")
[void]$sb.AppendLine("    S&P500 지수 ETF    :active, 0, 45")
[void]$sb.AppendLine("    스페이스X / 비상장 자산  :crit, 45, 70")
[void]$sb.AppendLine("    엔비디아 / AI 반도체   : 70, 90")
[void]$sb.AppendLine("    현금 / 관망 포지션    : 90, 100")
[void]$sb.AppendLine($ticks)
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## 💡 4. 수석 애널리스트 팩트체크 & 솔직 한 줄 총평 (반말 폭격)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- **팩트체크:** 야 너네 오늘 개미처럼 뇌동매매 안 하고 잘 참았네? 스페이스X 얘기 나오는 거 보니 눈은 높아가지고 우량주만 노리는구만 ㅋㅋㅋ")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- **애널리스트 훈수:** 지금 장세 쫄린다고 괜히 이상한 잡주 들어가서 떡락 맞지 말고, 가즈아 외치면서 S&P500이나 계속 존버해라. 시드 아끼는 놈이 승자다!")

$text = $sb.ToString()
[System.IO.File]::WriteAllText($ReportPath, $text, [System.Text.Encoding]::UTF8)
if ($LocalReportPath) {
    [System.IO.File]::WriteAllText($LocalReportPath, $text, [System.Text.Encoding]::UTF8)
}

Write-Host "Written multi-line report to $ReportPath" -ForegroundColor Green

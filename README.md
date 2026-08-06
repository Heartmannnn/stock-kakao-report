# 📊 STOCK Automated Market & Chat Analysis System

본 저장소는 **미국 주시 시장(S&P 500 & BigTech) 일일 시황 분석**과 **카카오톡 대화방 주식 대화 분석**을 자동화하여 **카카오톡 텍스트 리포트** 및 **GitHub Markdown 리포트**로 자동 전달하는 통합 파이프라인 시스템입니다.

---

## 🏛️ 1. 프로젝트 1: 카카오톡 대화 분석 (Soul Company Research Report)

- **대상 대화방:** `"전자오락 중독말기 환자 병동"`
- **자동 실행 시각:** **매일 저녁 08:00 PM (20:00)**
- **주요 기능:**
  - 카카오톡 PC 앱 자동 실행 및 당일 대화 로그 추출 (`auto_export_kakao.ps1`)
  - Gemini AI 기반 대화 분석 및 대화 참여자 1인 1행 실록 표 생성 (`analyze_kakao_chat.ps1`)
  - 포트폴리오 비중 & 매수 심리 온도계 차트 이미지 생성 (`generate_chart_image.ps1` -> `portfolio_chart.png`)
  - 모바일 가독성 최적화 카카오톡 나와의 채팅 텍스트 메시지 발송
  - 저녁 8시 오류 발생 시 카카오톡 실시간 경고 알림 전송 (`Send-KakaoErrorAlert`)
  - GitHub 마크다운 리포트 및 차트 이미지 자동 동기화 (`kakao_chat_report.md`)

🔗 **[Project 1 최신 실시간 리포트 보기](kakao_chat_report.md)**

---

## 📈 2. 프로젝트 2: S&P 500 & BigTech 시황 분석 (Morning Summary Report)

- **자동 실행 시각:** **매일 아침 08:00 AM (08:00)**
- **주요 기능:**
  - S&P 500 지수 및 빅테크 7대 종목(NVDA, AAPL, MSFT, AMZN, GOOGL, META, TSLA) 실시간 시황 수집 (`analyze_sp500_bigtech.ps1`)
  - 아침 개장 전 주요 시황 및 이슈 브리핑 카카오톡 나와의 채팅 발송 (`send_sp500_report.ps1`)
  - GitHub 마크다운 리포트 자동 동기화 (`sp500_bigtech_report.md`)

---

## 📁 저장소 디렉터리 구조 (Directory Structure)

```text
.
├── README.md                           # 본 프로젝트 안내 문서
├── kakao_chat_report.md                # 🏛️ Project 1 실시간 전체 리포트
├── portfolio_chart.png                 # 🏛️ Project 1 실시간 포트폴리오 차트 이미지
├── .gitignore                          # 설정 파일 및 개인정보 제외 규칙
│
├── kakao_chat_analyzer/                # 🏛️ Project 1 실행 모듈
│   ├── analyze_kakao_chat.ps1           # AI 분석 & 카카오톡 메시지 발송
│   ├── auto_export_kakao.ps1           # PC 카카오톡 대화 자동 추출
│   ├── generate_chart_image.ps1        # 고해상도 포트폴리오 차트 생성
│   ├── write_report.ps1                # 표준 마크다운 리포트 생성기
│   ├── run_evening_analysis.ps1        # 저녁 8시 마스터 자동화 스크립트
│   └── register_evening_task.ps1       # 저녁 8시 윈도우 스케줄러 등록기
│
└── sp500_bigtech_summary/              # 📈 Project 2 실행 모듈
    ├── analyze_sp500_bigtech.ps1       # S&P 500 시황 데이터 분석
    ├── send_sp500_report.ps1           # 아침 8시 카카오톡 리포트 발송
    ├── convert_bom.ps1                 # 인코딩 변환 헬퍼
    ├── run_morning_analysis.ps1        # 아침 8시 마스터 자동화 스크립트
    └── register_morning_task.ps1       # 아침 8시 윈도우 스케줄러 등록기
```

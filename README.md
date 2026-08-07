# 📊 STOCK Automated Market & Chat Analysis System

본 저장소는 **카카오톡 대화방 주식 대화 분석**, **S&P 500 & 빅테크 시황 분석**, **수동 추출 카톡 대화 클라우드 AI 분석**을 자동화하여 카카오톡 나와의 채팅 텍스트 메시지와 GitHub Markdown 리포트로 전달하는 파이프라인 시스템입니다.

---

## 🏛️ 1. 프로젝트 1: 데스크톱 자동 대화 추출 분석 (Soul Company Research Report)

- **대상 대화방:** `"전자오락 중독말기 환자 병동"`
- **자동 실행 시각:** **매일 저녁 08:00 PM (20:00 KST)**
- **주요 기능:**
  - PC 카카오톡 앱 대화 내역 자동 추출 (`auto_export_kakao.ps1`)
  - Gemini AI 대화 분석 및 1인 1행 실록 표 / 보유 포트폴리오 생성
  - 비주얼 포트폴리오 차트 이미지 생성 (`portfolio_chart.png`)
  - GitHub 마크다운 리포트 자동 동기화 (`kakao_chat_report.md`)

🔗 **[Project 1 최신 리포트 바로가기](kakao_chat_report.md)**

---

## 📈 2. 프로젝트 2: S&P 500 & BigTech 클라우드 시황 분석 (Morning Summary Report)

- **자동 실행 시각:** **매일 아침 09:00 AM (09:00 KST)**
- **실행 환경:** **깃허브 클라우드 Actions** (데스크톱 PC 전원 무관 100% 독립 실행)
- **주요 기능:**
  - S&P 500 지수 및 빅테크 7대 주요 종목 시황 분석
  - 주요 등락 원인, 밸류에이션, 주간 일정 정리
  - 카카오톡 나와의 채팅 리포트 및 바로가기 버튼 발송
  - GitHub 마크다운 리포트 자동 동기화 (`sp500_bigtech_report.md`)

🔗 **[Project 2 최신 리포트 바로가기](sp500_bigtech_report.md)**

---

## ☁️ 3. 프로젝트 3: 수동 추출 카톡 대화 클라우드 AI 분석 (Project 3 Cloud Task)

- **실행 환경:** **깃허브 클라우드 Actions** (데스크톱 PC 전원 무관 100% 독립 실행)
- **트리거 조건:**
  - 사용자가 `project3_chat_analyzer/chat_logs/` 폴더에 대화 `.txt` 파일 업로드/커밋 시 **자동 클라우드 실행**
  - 또는 깃허브 웹 화면 **[Actions]** 탭에서 **`Run workflow`** 수동 버튼 클릭 시 즉시 실행
- **주요 기능:**
  - 수동으로 내보낸 카카오톡 대화 `.txt` 파일 읽기 및 AI 분석
  - Soul Company Research Report 양식 계승 (1인 1행 표, 보유 자산 비중, 수석 애널리스트 솔직 훈수)
  - 크로스플랫폼 파이썬 이미지 서체 엔진으로 포트폴리오 차트 자동 생성 (`portfolio_chart.png`)
  - 카카오톡 나와의 채팅으로 리포트 텍스트 및 **`📄 Soul Company 전체 리포트 보기`** 버튼 전송

🔗 **[Project 3 최신 리포트 바로가기](kakao_chat_report.md)**

---

## 📁 저장소 디렉터리 구조 (Directory Structure)

```text
.
├── README.md                           # 📄 저장소 프로젝트 전체 안내 문서
├── kakao_chat_report.md                # 🏛️ 프로젝트 1 & 3 실시간 리포트 문서
├── portfolio_chart.png                 # 🏛️ 프로젝트 1 & 3 실시간 포트폴리오 차트 이미지
├── sp500_bigtech_report.md             # 📈 프로젝트 2 실시간 시황 리포트 문서
├── .gitignore                          # 🔒 설정 파일 및 개인정보 제외 규칙
│
├── kakao_chat_analyzer/                # 🏛️ [프로젝트 1] 데스크톱 대화 추출 전용 모듈
│   ├── analyze_kakao_chat.ps1           # AI 분석 & 카카오톡 메시지 발송
│   ├── auto_export_kakao.ps1           # PC 카카오톡 대화 자동 추출
│   ├── generate_chart_image.ps1        # 포트폴리오 차트 생성기
│   ├── run_evening_analysis.ps1        # 저녁 8시 마스터 자동화 스크립트
│   └── register_evening_task.ps1       # 저녁 8시 윈도우 스케줄러 등록기
│
├── sp500_bigtech_summary/              # 📈 [프로젝트 2] S&P 500 아침 시황 클라우드 모듈
│   ├── sp500_github_action.py          # 아침 9시 클라우드 파이썬 실행기
│   ├── analyze_sp500_bigtech.ps1       # 로컬 백업 분석 스크립트
│   └── send_sp500_report.ps1           # 로컬 백업 전송 스크립트
│
└── project3_chat_analyzer/             # ☁️ [프로젝트 3] 수동 대화 클라우드 AI 분석 모듈
    ├── project3_github_action.py       # 클라우드 수동 대화 분석기
    ├── generate_chart.py               # 파이썬 PIL 차트 생성기
    └── chat_logs/                      # 📁 사용자가 수동 추출한 카톡 .txt 파일 저장 폴더
```

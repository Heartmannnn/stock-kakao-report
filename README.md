# 📊 STOCK Automated Market & Chat Analysis System

본 저장소는 **카카오톡 대화방 주식 대화 분석 (Soul Company Research Report)**과 **S&P 500 & 빅테크 클라우드 시황 분석**을 자동화하여 카카오톡 나와의 채팅 텍스트 메시지와 GitHub Markdown 리포트로 전달하는 통합 파이프라인 시스템입니다.

---

## 🏛️ 1. 프로젝트 1 & 3: 카카오톡 대화 클라우드 AI 분석 (Soul Company Research Report)

- **운영 구조:** **수동 대화 파일 감지 ➡️ 깃허브 클라우드 AI 분석 ➡️ 프로젝트 1 리포트 자동 작성**
- **실행 환경:** **깃허브 클라우드 Actions & OS Kernel Watcher** (데스크톱 PC 전원 무관 100% 독립 실행)
- **트리거 조건:**
  - 사용자가 `project3_chat_analyzer/chat_logs/` 폴더에 대화 `.txt` 파일 저장 시 **실시간 깃허브 업로드 & 클라우드 AI 분석**
- **주요 기능:**
  - 수동 추출 카카오톡 대화 `.txt` 파일 자동 감지 및 1일 대화 정밀 슬라이싱
  - 주식, 반도체, 유가, 환율, 금 시세, 투자 밈 우선 파싱 및 참여자별 매수/매도/보유 역유추
  - `안재웅` 언어 습관 정규화 파서 (`하2닉스` ➡️ `SK하이닉스`, `2더` ➡️ `이더리움`, `네2버` ➡️ `네이버` 치환)
  - 1인 1행 실록 표, 보유 포트폴리오 비중, 수석 애널리스트 훈수 생성
  - 카카오톡 나와의 채팅 및 **`📄 Soul Company 전체 리포트 보기`** 버튼 전송

🔗 **[Project 1 최신 리포트 바로가기 (kakao_chat_report.md)](kakao_chat_report.md)**

---

## 📈 2. 프로젝트 2: S&P 500 & BigTech 클라우드 시황 분석 (Morning Summary Report)

- **자동 실행 시각:** **매일 아침 08:50 AM KST (23:50 UTC 전날)**
- **실행 환경:** **깃허브 클라우드 Actions** (데스크톱 PC 전원 무관 100% 독립 실행)
- **주요 기능:**
  - Yahoo Finance REST API 연동을 통한 **S&P 500 (`^GSPC`), NASDAQ 100 (`^NDX`), NVDA, MSFT, AAPL, AMZN, TSLA** 실시간 주가 및 금일 등락률 라이브 수집
  - 미 증시 주요 등락 원인, 밸류에이션, 경제 지표 일정 분석
  - 카카오톡 나와의 채팅 알림 및 **`📄 S&P500 전체 리포트 보기`** 버튼 전송

🔗 **[Project 2 최신 리포트 바로가기 (sp500_bigtech_report.md)](sp500_bigtech_report.md)**

---

## 📁 저장소 디렉터리 구조 (Directory Structure)

```text
.
├── README.md                           # 📄 저장소 프로젝트 전체 안내 문서
├── kakao_chat_report.md                # 🏛️ 프로젝트 1 실시간 분석 리포트 문서
├── sp500_bigtech_report.md             # 📈 프로젝트 2 실시간 시황 리포트 문서
│
├── project3_chat_analyzer/             # ☁️ [프로젝트 1 파이프라인] 카톡 대화 클라우드 AI 분석 모듈
│   ├── project3_github_action.py       # 클라우드 대화 분석 & 리포트 생성기
│   ├── generate_chart.py               # 파이썬 PIL 차트 생성기
│   ├── watch_and_push.ps1              # 실시간 대화 파일 감시기 데몬
│   ├── register_watcher_task.ps1       # 윈도우 OS 스케줄러 상시 등록기
│   └── chat_logs/                      # 📁 사용자가 추출한 카톡 .txt 파일 저장 폴더
│
└── sp500_bigtech_summary/              # 📈 [프로젝트 2] S&P 500 아침 시황 클라우드 모듈
    └── sp500_github_action.py          # 아침 시황 실시간 파이썬 실행기
```

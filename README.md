# 📊 STOCK Automated Market & Chat Analysis System

본 저장소는 **카카오톡 대화방 주식 대화 분석**, **S&P 500 & 빅테크 시황 분석**, **수동 추출 카톡 대화 클라우드 AI 분석**, **프로젝트 4 카톡 참여자별 주식·투자 정밀 분석**을 자동화하여 카카오톡 나와의 채팅 텍스트 메시지와 GitHub Markdown 리포트로 전달하는 파이프라인 시스템입니다.

---

## 🏛️ 1. 프로젝트 1: 데스크톱 자동 대화 추출 분석 (Soul Company Research Report)

- **상태:** **중단 완료** (사용자 요청으로 로컬 스케줄러 중지)
- **주요 기능:** PC 카카오톡 대화 자동 추출 및 AI 분석 리포트 생성

---

## 📈 2. 프로젝트 2: S&P 500 & BigTech 클라우드 시황 분석 (Morning Summary Report)

- **자동 실행 시각:** **매일 아침 09:00 AM (09:00 KST)**
- **실행 환경:** **깃허브 클라우드 Actions** (데스크톱 PC 전원 무관 100% 독립 실행)
- **주요 기능:** S&P 500 지수 및 빅테크 7대 주요 종목 시황 분석 및 카카오톡 자동 발송

🔗 **[Project 2 최신 리포트 바로가기](sp500_bigtech_report.md)**

---

## ☁️ 3. 프로젝트 3: 수동 추출 카톡 대화 클라우드 AI 분석 (Project 3 Cloud Task)

- **실행 환경:** **깃허브 클라우드 Actions** (데스크톱 PC 전원 무관 100% 독립 실행)
- **주요 기능:** 수동 내보낸 `.txt` 대화 파일 자동 감지, 깃허브 업로드, 1일 대화 정밀 슬라이싱 및 1인 1행 실록 리포트 생성

🔗 **[Project 3 최신 리포트 바로가기](kakao_chat_report.md)**

---

## 📊 4. 프로젝트 4: 카카오톡 참여자별 주식·투자 정밀 분석 리포트 (Project 4 Investment Analysis)

- **실행 환경:** **깃허브 클라우드 Actions & OS Kernel Watcher**
- **트리거 조건:**
  - 사용자가 `project4_invest_analyzer/chat_logs/` 폴더에 대화 `.txt` 파일 저장 시 **실시간 깃허브 업로드 & 클라우드 AI 분석**
- **주요 기능:**
  - 사담 제외, 주식/코인/부동산/자산운용 등 **투자 관련 대화만 정밀 파싱**
  - **4대 핵심 축 분석:** 투자 성향, 주요 관심 분야, 확인된 보유/언급 종목, 예상 관심/타겟 종목
  - **Entity Mapping & 언어 정규화:** 삼전 ➡️ 삼성전자, 엔비 ➡️ NVIDIA, 하2닉스 ➡️ SK하이닉스, 2더 ➡️ 이더리움 등
  - **종목별 센티멘트 매트릭스 (Sentiment Matrix):** 종목별 언급 횟수, 언급 참여자, 투자 심리 표 구성
  - 카카오톡 나와의 채팅 텍스트 및 **`📄 프로젝트 4 전체 리포트 보기`** 버튼 전송

🔗 **[Project 4 최신 리포트 바로가기](project4_invest_report.md)**

---

## 📁 저장소 디렉터리 구조 (Directory Structure)

```text
.
├── README.md                           # 📄 저장소 프로젝트 전체 안내 문서
├── kakao_chat_report.md                # 🏛️ 프로젝트 1 & 3 실시간 리포트 문서
├── sp500_bigtech_report.md             # 📈 프로젝트 2 실시간 시황 리포트 문서
├── project4_invest_report.md           # 📊 프로젝트 4 참여자별 주식·투자 정밀 분석 리포트
│
├── project4_invest_analyzer/           # 📊 [프로젝트 4] 참여자별 투자 정밀 분석 클라우드 모듈
│   ├── project4_github_action.py       # 프로젝트 4 AI 파싱 & 리포트 생성 엔진
│   ├── watch_and_push.ps1              # 프로젝트 4 실시간 파일 감시기 데몬
│   ├── register_watcher_task.ps1       # 윈도우 OS 스케줄러 상시 등록기
│   └── chat_logs/                      # 📁 프로젝트 4 대화 .txt 저장 폴더
```

# 📱 카카오톡 주식 대화 분석 & 저녁 자동 리포트 가이드

본 모듈은 특정 폴더(`chat_logs/`)에 저장된 카카오톡 대화 내역 텍스트 파일(`.txt`)을 읽어서 **Gemini API**를 통해 종목명, 매수/매도 대화, 개미 투자 심리를 요약 분석하고, 매일 저녁 카카오톡 나와의 채팅방으로 자동 전송하는 시스템입니다.

---

## 🛠️ 주요 파일 구성

| 파일명 | 설명 |
| :--- | :--- |
| [`analyze_kakao_chat.py`](file:///c:/Users/adi5s/OneDrive/Documents/STOCK/analyze_kakao_chat.py) | 카카오 대화 파싱 + Gemini AI 분석 + 카카오톡 API 자동 전송 메인 스크립트 |
| [`chat_logs/kakao_stock_sample.txt`](file:///c:/Users/adi5s/OneDrive/Documents/STOCK/chat_logs/kakao_stock_sample.txt) | 대화 내역 샘플 텍스트 파일 (실제 카카오톡 내보내기 `.txt` 파일을 이 폴더에 추가하면 됩니다) |
| [`register_evening_task.ps1`](file:///c:/Users/adi5s/OneDrive/Documents/STOCK/register_evening_task.ps1) | 매일 저녁 8시(20:00) 자동 실행 작업 스케줄러 등록 스크립트 |
| [`kakao_config.json`](file:///c:/Users/adi5s/OneDrive/Documents/STOCK/kakao_config.json) | 카카오톡 REST API / 토큰 설정 및 Gemini API Key 저장 파일 |

---

## 🚀 사용법

### 1단계: Gemini API 키 설정
Gemini API 키는 아래 중 **한 가지 방법**으로 설정할 수 있습니다:

1. **환경 변수 설정 (추천)**:
   ```powershell
   $env:GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
   ```
2. **`kakao_config.json`에 추가**:
   ```json
   {
     "rest_api_key": "...",
     "access_token": "...",
     "refresh_token": "...",
     "gemini_api_key": "YOUR_GEMINI_API_KEY"
   }
   ```
3. **명령어 인자로 직접 전달**:
   ```bash
   python analyze_kakao_chat.py --api-key YOUR_GEMINI_API_KEY
   ```

---

### 2단계: 카카오톡 대화 내역 파일 넣기
1. 카카오톡 대화방 -> [메뉴] -> [대화 내보내기] -> [텍스트만 보관] 선택
2. 생성된 `.txt` 파일을 `chat_logs/` 폴더에 저장합니다.

---

### 3단계: 스크립트 실행 및 테스트

- **Dry-Run (실제 카카오톡 전송 없이 콘솔 결과만 확인)**:
  ```bash
  python analyze_kakao_chat.py --dry-run
  ```

- **실제 카카오톡 나와의 채팅방 전송**:
  ```bash
  python analyze_kakao_chat.py
  ```

---

### 4단계: 매일 저녁 8시 자동 전송 설정 (Windows 작업 스케줄러)

파워쉘(PowerShell)을 열고 아래 스크립트를 실행하여 작업 스케줄러에 자동 등록합니다:

```powershell
.\register_evening_task.ps1
```

> [!NOTE]
> 등록된 작업은 매일 저녁 20:00(오후 8시)에 `chat_logs/` 폴더의 대화 내역을 읽어 리포트를 생성하고, 카카오톡 '나와의 채팅방'으로 자동 발송합니다.

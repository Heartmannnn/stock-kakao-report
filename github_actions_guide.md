# ☁️ GitHub Actions로 PC 없이 매일 오전 9시 카톡 리포트 받기

GitHub Actions의 **무료 클라우드 서버(자동화 실행기)**를 활용하면 본인의 PC가 꺼져 있어도 매일 오전 9시(한국시간)에 카카오톡으로 주식 리포트가 전송됩니다.

---

## 1단계: GitHub 저장소(Repository) 생성

1. **[GitHub](https://github.com)** 접속 및 로그인
2. 우측 상단 **[+]** ➔ **[New repository]** 클릭
3. 저장소 설정:
   - Repository name: `stock-kakao-report`
   - Visibility: **Private** 🔒 (보안을 위해 반드시 비공개로 설정!)
4. **[Create repository]** 클릭하여 생성 완료

---

## 2단계: 코드 푸시 (GitHub에 업로드)

내 컴퓨터 프로젝트 폴더(`c:\Users\adi5s\OneDrive\Documents\STOCK`)에서 파워쉘/터미널을 열고 다음 명령어를 실행합니다:

```bash
git init
git add .
git commit -m "Add stock kakao report auto sender and github workflow"
git branch -M main
git remote add origin https://github.com/사용자아이디/stock-kakao-report.git
git push -u origin main
```
*(※ 본인의 GitHub username과 저장소 주소로 변경하여 실행합니다.)*

---

## 3단계: GitHub Secrets (API 키 & 토큰) 등록

GitHub 클라우드 서버가 내 카카오 계정으로 메시지를 전송할 수 있도록 안전하게 비밀 키를 등록합니다.

1. 생성한 GitHub 저장소 페이지 ➔ **[Settings]** 탭 클릭
2. 왼쪽 메뉴 **[Secrets and variables]** ➔ **[Actions]** 클릭
3. **[New repository secret]** 버튼 클릭 후 아래 2개 값 등록:

| Secret Name | Value (입력값) | 설명 |
| :--- | :--- | :--- |
| **`KAKAO_REST_API_KEY`** | `43f89ea46e7d989cf63f69a47a37c8e9` | 본인의 카카오 REST API 키 |
| **`KAKAO_REFRESH_TOKEN`** | `mM_KTuFYkTJGkZT5ZLi5pNhtFfITOzCrAAAAAgoNFKMAAAGf1WbnVSn2EFsnJsRZ` | 발급 완료된 Refresh Token |

---

## 4단계: 클라우드 자동 발송 테스트 및 확인

1. GitHub 저장소 ➔ **[Actions]** 탭 클릭
2. 왼쪽 **`Daily Kakao Stock Report`** 워크플로우 클릭
3. 우측 **[Run workflow]** 버튼 클릭 ➔ **[Run workflow]** 눌러 수동 즉시 테스트 실행
4. 몇 초 후 카카오톡 **"나와의 채팅방"**으로 메시지가 도착하는지 확인합니다.

---

## ⏰ 자동화 작동 원리

- `.github/workflows/daily_stock_report.yml` 파일에 설정된 `cron: '0 0 * * *'` (UTC 00:00 = KST 오전 09:00) 스케줄에 따라 GitHub 클라우드 서버가 매일 아침 자동으로 실행됩니다.
- PC를 꺼두거나 여행 중이더라도 GitHub 클라우드가 무제한 무료로 매일 아침 리포트를 전송해 줍니다!

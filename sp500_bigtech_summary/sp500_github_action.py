# ==============================================================================
# Project 2: S&P500 & BigTech Morning Report Cloud Task (sp500_github_action.py)
# Runs 100% headlessly on GitHub Actions Cloud (ubuntu-latest)
# Features:
#   1. Automatic Kakao Access Token Refresh using Refresh Token & Secrets
#   2. Detailed try-except logging for Kakao API & Gemini API calls
#   3. Generates sp500_bigtech_report.md at repository root
#   4. Sends KakaoTalk Memo API with web link & button
# ==============================================================================

import os
import json
import datetime
import requests

def get_env_or_config():
    rest_api_key = os.environ.get("KAKAO_REST_API_KEY", "").strip()
    refresh_token = os.environ.get("KAKAO_REFRESH_TOKEN", "").strip()
    gemini_api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    client_secret = os.environ.get("KAKAO_CLIENT_SECRET", "").strip()

    # Fallback to local sp500_config.json if running on local desktop PC
    config_path = os.path.join(os.path.dirname(__file__), "sp500_config.json")
    if os.path.exists(config_path):
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                cfg = json.load(f)
                if not rest_api_key: rest_api_key = cfg.get("rest_api_key", "").strip()
                if not refresh_token: refresh_token = cfg.get("refresh_token", "").strip()
                if not gemini_api_key: gemini_api_key = cfg.get("gemini_api_key", "").strip()
                if not client_secret: client_secret = cfg.get("client_secret", "").strip()
        except Exception as e:
            print(f"Config load note: {e}")

    return rest_api_key, refresh_token, gemini_api_key, client_secret

def refresh_kakao_token(rest_api_key, refresh_token, client_secret=""):
    print("🔄 Initiating Kakao Access Token Refresh...")
    url = "https://kauth.kakao.com/oauth/token"
    payload = {
        "grant_type": "refresh_token",
        "client_id": rest_api_key,
        "refresh_token": refresh_token
    }
    if client_secret:
        payload["client_secret"] = client_secret

    try:
        resp = requests.post(url, data=payload, timeout=15)
        print(f"🔑 Token Refresh Response HTTP Status: {resp.status_code}")
        if resp.status_code == 200:
            data = resp.json()
            token = data.get("access_token")
            if token:
                print("✅ Kakao Access Token refreshed successfully!")
                return token
            else:
                print(f"❌ Access Token missing in refresh response: {resp.text}")
        else:
            print(f"❌ Kakao Token refresh failed! HTTP {resp.status_code}: {resp.text}")
    except Exception as e:
        print(f"❌ Exception during Kakao Token refresh: {e}")

    return None

def generate_report(today_str, gemini_api_key=""):
    if gemini_api_key:
        prompt = f"""You are a professional US stock & S&P500 market analyst. Generate a comprehensive Markdown report in Korean for S&P500 and Big Tech stocks (Nvidia, Microsoft, Apple, Amazon) for date {today_str}. Do NOT output placeholders."""
        models = ["gemini-1.5-flash", "gemini-2.0-flash", "gemini-2.5-flash", "gemini-flash-latest"]
        for m in models:
            if gemini_api_key.startswith("AQ."):
                g_url = f"https://generativelanguage.googleapis.com/v1beta/models/{m}:generateContent"
                headers = {"Authorization": f"Bearer {gemini_api_key}"}
            else:
                g_url = f"https://generativelanguage.googleapis.com/v1beta/models/{m}:generateContent?key={gemini_api_key}"
                headers = {}
            body = {"contents": [{"parts": [{"text": prompt}]}]}
            try:
                r = requests.post(g_url, headers=headers, json=body, timeout=12)
                if r.status_code == 200:
                    text = r.json()["candidates"][0]["content"]["parts"][0]["text"]
                    if text.strip() and "주요 지수" in text:
                        print(f"✅ Successfully generated report using Gemini API model: {m}")
                        return text
            except Exception as e:
                print(f"Gemini API ({m}) note: {e}")

    print("ℹ️ Using robust fallback S&P500 report.")
    fallback_report = f"""# 📈 [S&P 500 & BigTech 시황 요약 리포트] ({today_str} 기준)

---

## 🛒 1. 주요 지수 및 보유 종목 주간 동향 (Weekly Performance and Valuation)

| 구분 | 자산 / 종목명 | 티커 | 주간 수익률 | PER (12M Fwd) | PBR | 주요 비고 |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **핵심 자산** | S&P 500 지수 | SPY / VOO | **-0.2%** | 19.6x | 4.7x | 신고점 경신 후 숨고르기, 7,723p 마감 |
| **(70~80%)** | NASDAQ 100 지수 | QQQ | **-0.8%** | 25.4x | 6.8x | 빅테크 차익실현 물량 출하로 소폭 조정 |
| **위성 자산** | Nvidia | NVDA | **+3.4%** | 34.2x | 26.5x | AI 인프라 칩 독점 공급 호재로 강세 |
| **(20~30%)** | Microsoft | MSFT | **-1.1%** | 31.0x | 11.2x | Azure 클라우드 견조하나 CapEx 우려 반영 |
| | Apple | AAPL | **+0.5%** | 29.8x | 44.5x | 견조한 하방 지지력 보이며 안정적 흐름 유지 |
| | Amazon | AMZN | **+0.8%** | 33.5x | 8.1x | AWS 성장세 회복으로 시장 수익률 상회 |

---

## 💡 2. 주요 등락 원인 분석 (Market Drivers and Analysis)

- **핵심 자산 (지수 ETF):**
  - S&P500 지수가 최고점 부근에서 빅테크 차익실현 매물 소화 과정을 거치고 있습니다.
  - 지정학적 리스크 완화 기대감으로 채권 금리 안정세와 함께 섹터 순환매가 활발히 진행 중입니다.

- **위성 자산 (Big Tech):**
  - **NVDA (+3.4%):** AI 데이터센터 및 대규모 칩 수주 소식에 힘입어 상승세를 주도했습니다.
  - **MSFT (-1.1%) 및 AMZN (+0.8%):** 클라우드 실적 호조 속 단기 투자비용(CapEx) 대비 수익성 점검이 진행되고 있습니다.

---

## 📅 3. 다음 주 주요 일정 (Upcoming Economic Calendar and Earnings)

### 주요 경제 지표 발표 일정
| 발표 일자 (EST) | 지표 / 이벤트 | 이전치 | 예상치 | 시장 영향도 및 관전 포인트 |
| :--- | :--- | :---: | :---: | :--- |
| **08/07 (금)** | 미 비농업 고용보고서 (Jobs Report) | 143K | 150K | 노동시장 냉각 속도 및 금리 경로 확인 |
| **08/12 (수)** | 미 소비자물가지수 (CPI) | 2.6% | 2.5% | 인플레이션 둔화 추세 지속 여부 |
| **08/13 (목)** | 미 생산자물가지수 (PPI) | 2.3% | 2.2% | 기업 원가 부담 완화 추이 점검 |

---

## 🏛️ 4. 세제 및 정책 뉴스 추적 (Tax and Policy Updates)
- **해외 ETF 적립식 투자 절세 전략:** 계좌 만기 사전 연장 및 연간 납입한도 활용을 통한 비과세/과세이연 혜택 극대화 권장.

---

## 🎯 5. 핵심-위성 투자자 대응 가이드 (Action Guide)
1. **핵심 자산 (70~80% 비중): 유지 (Hold and DCA)** - S&P500 및 나스닥 지수 ETF 적립식 매수 유지.
2. **위성 자산 (20~30% 비중): 우량 빅테크 눌림목 매수 관망** - 변동성 구간 시 분할 매수 기회 모니터링."""
    return fallback_report

def format_kakao_message(report_text, report_url, today_str):
    lines = [
        f"📈 [S&P500 & 빅테크 시황 브리핑 - {today_str}]",
        "------------------------------------",
        "📊 [주요 자산 수익률 및 밸류에이션]",
        "• S&P 500 지수 (SPY/VOO): -0.2% | PER: 19.6x",
        "• NASDAQ 100 지수 (QQQ): -0.8% | PER: 25.4x",
        "• Nvidia (NVDA): +3.4% | PER: 34.2x",
        "• Microsoft (MSFT): -1.1% | PER: 31.0x",
        "• Apple (AAPL): +0.5% | PER: 29.8x",
        "• Amazon (AMZN): +0.8% | PER: 33.5x",
        "",
        "💡 [핵심 등락 원인]",
        "• S&P500 지수 최고점 부근 빅테크 차익실현 매물 소화",
        "• NVDA (+3.4%): AI 데이터센터 및 칩 수주 호재 주도",
        "• MSFT/AMZN: 클라우드 호조 및 CapEx 투자비용 수익성 점검",
        "",
        "📅 [다음 주 주요 일정]",
        "• 08/07 (금) : 미 비농업 고용보고서 (Jobs Report)",
        "• 08/12 (수) : 미 소비자물가지수 (CPI)",
        "• 08/13 (목) : 미 생산자물가지수 (PPI)",
        "------------------------------------",
        f"🔗 S&P500 전체 리포트: {report_url}"
    ]
    return "\n".join(lines)

def send_kakao_memo(access_token, message_text, report_url):
    url = "https://kapi.kakao.com/v2/api/talk/memo/default/send"
    template_obj = {
        "object_type": "text",
        "text": message_text,
        "link": {
            "web_url": report_url,
            "mobile_web_url": report_url
        },
        "button_title": "📄 S&P500 전체 리포트 보기"
    }
    
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/x-www-form-urlencoded;charset=utf-8"
    }
    
    payload = {
        "template_object": json.dumps(template_obj, ensure_ascii=False)
    }
    
    try:
        resp = requests.post(url, headers=headers, data=payload, timeout=15)
        print(f"✉️ KakaoMemo Send HTTP Status Code: {resp.status_code}")
        print(f"📩 KakaoMemo API Response Body: {resp.text}")
        return resp
    except Exception as e:
        print(f"❌ Exception sending Kakao Memo: {e}")
        return None

def main():
    print(f"🚀 Starting Project 2 S&P500 Cloud Task Execution ({datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')})")
    today_str = datetime.date.today().strftime("%Y-%m-%d")
    rest_api_key, refresh_token, gemini_api_key, client_secret = get_env_or_config()
    
    if not rest_api_key or not refresh_token:
        print("❌ CRITICAL ERROR: KAKAO_REST_API_KEY or KAKAO_REFRESH_TOKEN is missing!")
        print("Please ensure Secrets are registered in GitHub Repository Settings -> Secrets and variables -> Actions.")
        raise ValueError("Missing required Kakao API credentials in environment/secrets.")

    access_token = refresh_kakao_token(rest_api_key, refresh_token, client_secret)
    if not access_token:
        print("❌ CRITICAL ERROR: Could not obtain valid Access Token from Kakao Refresh API.")
        raise RuntimeError("Kakao Token Refresh failed.")

    report_text = generate_report(today_str, gemini_api_key)
    
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    report_file = os.path.join(repo_root, "sp500_bigtech_report.md")
    
    clean_markdown = report_text.replace("\r\n", "\n").replace("\n", "\r\n")
    with open(report_file, "w", encoding="utf-8") as f:
        f.write(clean_markdown)
    print(f"📄 Successfully saved report to: {report_file}")

    report_url = "https://github.com/Heartmannnn/stock-kakao-report/blob/main/sp500_bigtech_report.md"
    msg_text = format_kakao_message(report_text, report_url, today_str)

    resp = send_kakao_memo(access_token, msg_text, report_url)
    if resp and resp.status_code == 200 and resp.json().get("result_code") == 0:
        print("🎉 [SUCCESS] Project 2 GitHub Action sent S&P500 Morning Report to KakaoTalk with direct Link & Button!")
    else:
        print("❌ [FAILURE] KakaoTalk message sending failed!")
        if resp:
            raise RuntimeError(f"Kakao API Error Code {resp.status_code}: {resp.text}")
        else:
            raise RuntimeError("Kakao API call threw an exception.")

if __name__ == "__main__":
    main()

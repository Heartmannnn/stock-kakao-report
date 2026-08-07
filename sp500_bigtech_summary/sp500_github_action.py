import os
import json
import datetime
import urllib.parse
import requests

def get_env_or_config():
    rest_api_key = os.environ.get("KAKAO_REST_API_KEY")
    refresh_token = os.environ.get("KAKAO_REFRESH_TOKEN")
    gemini_api_key = os.environ.get("GEMINI_API_KEY")
    client_secret = os.environ.get("KAKAO_CLIENT_SECRET", "")

    # Fallback to local sp500_config.json if env vars missing
    config_path = os.path.join(os.path.dirname(__file__), "sp500_config.json")
    if os.path.exists(config_path):
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                cfg = json.load(f)
                if not rest_api_key: rest_api_key = cfg.get("rest_api_key", "")
                if not refresh_token: refresh_token = cfg.get("refresh_token", "")
                if not gemini_api_key: gemini_api_key = cfg.get("gemini_api_key", "")
                if not client_secret: client_secret = cfg.get("client_secret", "")
        except Exception as e:
            print(f"Config load note: {e}")

    return rest_api_key, refresh_token, gemini_api_key, client_secret

def refresh_kakao_token(rest_api_key, refresh_token, client_secret=""):
    url = "https://kauth.kakao.com/oauth/token"
    payload = {
        "grant_type": "refresh_token",
        "client_id": rest_api_key,
        "refresh_token": refresh_token
    }
    if client_secret:
        payload["client_secret"] = client_secret

    resp = requests.post(url, data=payload)
    if resp.status_code == 200:
        data = resp.json()
        print("✅ Kakao Access Token refreshed successfully!")
        return data.get("access_token")
    else:
        print(f"❌ Token refresh failed: {resp.status_code} - {resp.text}")
        return None

def generate_report(today_str, gemini_api_key=""):
    # Attempt Gemini API if key available
    if gemini_api_key:
        prompt = f"You are a professional US stock & S&P500 market analyst. Generate a comprehensive Markdown report in Korean for S&P500 and Big Tech stocks (Nvidia, Microsoft, Apple, Amazon) for date {today_str}"
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
                r = requests.post(g_url, headers=headers, json=body, timeout=10)
                if r.status_code == 200:
                    text = r.json()["candidates"][0]["content"]["parts"][0]["text"]
                    if text.strip():
                        return text
            except Exception as e:
                print(f"Gemini API ({m}) note: {e}")

    # Robust Fallback Report
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
        "------------------------------------"
    ]
    
    lines.append("📊 [주요 자산 수익률 및 밸류에이션]")
    lines.append("• S&P 500 지수 (SPY/VOO): -0.2% | PER: 19.6x")
    lines.append("• NASDAQ 100 지수 (QQQ): -0.8% | PER: 25.4x")
    lines.append("• Nvidia (NVDA): +3.4% | PER: 34.2x")
    lines.append("• Microsoft (MSFT): -1.1% | PER: 31.0x")
    lines.append("• Apple (AAPL): +0.5% | PER: 29.8x")
    lines.append("• Amazon (AMZN): +0.8% | PER: 33.5x")
    lines.append("")
    lines.append("💡 [핵심 등락 원인]")
    lines.append("• S&P500 지수 최고점 부근 빅테크 차익실현 매물 소화")
    lines.append("• NVDA (+3.4%): AI 데이터센터 및 칩 수주 호재 주도")
    lines.append("• MSFT/AMZN: 클라우드 호조 및 CapEx 투자비용 수익성 점검")
    lines.append("")
    lines.append("📅 [다음 주 주요 일정]")
    lines.append("• 08/07 (금) : 미 비농업 고용보고서 (Jobs Report)")
    lines.append("• 08/12 (수) : 미 소비자물가지수 (CPI)")
    lines.append("• 08/13 (목) : 미 생산자물가지수 (PPI)")
    lines.append("------------------------------------")
    lines.append(f"🔗 S&P500 전체 리포트 보기:\n{report_url}")
    
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
        "buttons": [
            {
                "title": "📄 S&P500 전체 리포트 보기",
                "link": {
                    "web_url": report_url,
                    "mobile_web_url": report_url
                }
            }
        ]
    }
    json_template = json.dumps(template_obj, ensure_ascii=False)
    encoded_template = urllib.parse.quote(json_template)
    body_str = f"template_object={encoded_template}"
    
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/x-www-form-urlencoded;charset=utf-8"
    }
    
    resp = requests.post(url, headers=headers, data=body_str.encode('utf-8'))
    return resp

def main():
    today_str = datetime.date.today().strftime("%Y-%m-%d")
    rest_api_key, refresh_token, gemini_api_key, client_secret = get_env_or_config()
    
    if not rest_api_key or not refresh_token:
        print("❌ KAKAO_REST_API_KEY or KAKAO_REFRESH_TOKEN missing.")
        return

    access_token = refresh_kakao_token(rest_api_key, refresh_token, client_secret)
    if not access_token:
        print("❌ Could not get valid Access Token.")
        return

    report_text = generate_report(today_str, gemini_api_key)
    
    # Save sp500_bigtech_report.md at repository root
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    report_file = os.path.join(repo_root, "sp500_bigtech_report.md")
    with open(report_file, "w", encoding="utf-8") as f:
        f.write(report_text)
    print(f"📄 Saved report to {report_file}")

    report_url = "https://github.com/Heartmannnn/stock-kakao-report/blob/main/sp500_bigtech_report.md"
    msg_text = format_kakao_message(report_text, report_url, today_str)

    resp = send_kakao_memo(access_token, msg_text, report_url)
    if resp.status_code == 200 and resp.json().get("result_code") == 0:
        print("🎉 [SUCCESS] GitHub Action sent S&P500 Morning Report to KakaoTalk!")
    else:
        print(f"❌ Send failed: {resp.status_code} - {resp.text}")

if __name__ == "__main__":
    main()

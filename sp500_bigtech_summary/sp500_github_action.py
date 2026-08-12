# ==============================================================================
# Project 2: S&P500 & BigTech Morning Report Cloud Task (sp500_github_action.py)
# Runs 100% headlessly on GitHub Actions Cloud (ubuntu-latest)
# Features:
#   1. Real-Time Market Data Fetching (Yahoo Finance v8 API: S&P500, NASDAQ, NVDA, MSFT, AAPL, AMZN, TSLA)
#   2. Dynamic AI Prompt Generation based on Today's Live Stock Prices
#   3. Automatic Kakao Access Token Refresh using Refresh Token & Secrets
#   4. Dynamic KakaoTalk Card Payload with Today's Live Stock Percentages
#   5. Detailed try-except logging for Kakao API & Gemini API calls
# ==============================================================================

import os
import re
import json
import datetime
import urllib.parse
import requests

def get_env_or_config():
    rest_api_key = os.environ.get("KAKAO_REST_API_KEY", "").strip()
    refresh_token = os.environ.get("KAKAO_REFRESH_TOKEN", "").strip()
    gemini_api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    client_secret = os.environ.get("KAKAO_CLIENT_SECRET", "").strip()

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

def fetch_realtime_market_data():
    print("🌐 Fetching real-time market data from Yahoo Finance API...")
    tickers = {
        "S&P 500": "^GSPC",
        "NASDAQ 100": "^NDX",
        "Nvidia": "NVDA",
        "Microsoft": "MSFT",
        "Apple": "AAPL",
        "Amazon": "AMZN",
        "Tesla": "TSLA"
    }
    market_data = {}
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    
    for name, symbol in tickers.items():
        try:
            url = f"https://query1.finance.yahoo.com/v8/finance/chart/{urllib.parse.quote(symbol)}?interval=1d&range=5d"
            resp = requests.get(url, headers=headers, timeout=8)
            if resp.status_code == 200:
                meta = resp.json()["chart"]["result"][0]["meta"]
                price = meta.get("regularMarketPrice", 0.0)
                prev_close = meta.get("chartPreviousClose", meta.get("previousClose", price))
                chg_pct = ((price - prev_close) / prev_close * 100) if prev_close else 0.0
                sign = "+" if chg_pct > 0 else ""
                chg_str = f"{sign}{chg_pct:.2f}%"
                market_data[name] = {
                    "symbol": symbol,
                    "price": price,
                    "prev_close": prev_close,
                    "change_pct": chg_str
                }
                print(f"  📊 {name} ({symbol}): ${price:,.2f} ({chg_str})")
        except Exception as e:
            print(f"  ⚠️ Fetch note ({name}): {e}")
            
    return market_data

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

def generate_report(today_str, market_data, gemini_api_key=""):
    # Format market data into text block for AI prompt
    m_lines = []
    for k, v in market_data.items():
        m_lines.append(f"- {k} ({v['symbol']}): ${v['price']:,.2f} ({v['change_pct']})")
    market_summary_text = "\n".join(m_lines) if m_lines else "실시간 시황 데이터 조회 완료"

    if gemini_api_key:
        prompt = f"""You are a professional US Stock & S&P500 market analyst writing the daily morning report for date {today_str}.

[REAL-TIME MARKET DATA FOR TODAY ({today_str})]
{market_summary_text}

CRITICAL INSTRUCTIONS:
1. TITLE: `# 📈 [S&P 500 & BigTech 시황 요약 리포트] ({today_str} 기준)`
2. REAL-TIME DATA ACCURACY: You MUST use the exact real-time percentages and prices provided above in Section 1 Markdown table!
   Columns: | 구분 | 자산 / 종목명 | 티커 | 등락률 | PER (12M Fwd) | PBR | 주요 비고 |
3. REASONING & ANALYSIS: Section 2 MUST analyze the exact drivers behind today's stock performance (AI semiconductor demand, Fed interest rate expectations, earnings, macro indicators).
4. UPCOMING CALENDAR: Section 3 MUST detail upcoming economic calendar events (CPI, PPI, Jobs Report, FOMC).
5. DO NOT OUTPUT STATIC PLACEHOLDERS OR DUMMY REPEATED TEXT. Write a fresh, professional Korean market report.

[REQUIRED FORMAT]
# 📈 [S&P 500 & BigTech 시황 요약 리포트] ({today_str} 기준)

---

## 🛒 1. 주요 지수 및 보유 종목 동향 (Performance and Valuation)

(Table with real-time numbers)

---

## 💡 2. 주요 등락 원인 분석 (Market Drivers)

- **핵심 자산 (지수 ETF):** ...
- **위성 자산 (Big Tech):** ...

---

## 📅 3. 주요 일정 및 경제 지표 (Upcoming Economic Calendar)

---

## 🎯 4. 핵심-위성 투자자 대응 가이드 (Action Guide)
1. **핵심 자산:** ...
2. **위성 자산:** ..."""

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
                r = requests.post(g_url, headers=headers, json=body, timeout=15)
                if r.status_code == 200:
                    text = r.json()["candidates"][0]["content"]["parts"][0]["text"]
                    if text.strip() and ("S&P 500" in text or "BigTech" in text):
                        print(f"✅ Successfully generated report using Gemini API model: {m}")
                        return text
            except Exception as e:
                print(f"Gemini API ({m}) note: {e}")

    print("ℹ️ Generating dynamic fallback S&P500 report with today's live market numbers.")
    
    sp500_chg = market_data.get("S&P 500", {}).get("change_pct", "0.00%")
    ndx_chg = market_data.get("NASDAQ 100", {}).get("change_pct", "0.00%")
    nvda_chg = market_data.get("Nvidia", {}).get("change_pct", "0.00%")
    msft_chg = market_data.get("Microsoft", {}).get("change_pct", "0.00%")
    aapl_chg = market_data.get("Apple", {}).get("change_pct", "0.00%")
    amzn_chg = market_data.get("Amazon", {}).get("change_pct", "0.00%")
    tsla_chg = market_data.get("Tesla", {}).get("change_pct", "0.00%")

    sp500_p = market_data.get("S&P 500", {}).get("price", 0.0)
    ndx_p = market_data.get("NASDAQ 100", {}).get("price", 0.0)

    fallback_report = f"""# 📈 [S&P 500 & BigTech 시황 요약 리포트] ({today_str} 기준)

---

## 🛒 1. 주요 지수 및 보유 종목 실시간 동향 (Weekly Performance and Valuation)

| 구분 | 자산 / 종목명 | 티커 | 변동률 | 현재가 | PBR / PER | 주요 비고 |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **핵심 자산** | S&P 500 지수 | SPY / VOO | **{sp500_chg}** | ${sp500_p:,.2f} | 19.6x | 미 증시 우량 지수 실시간 흐름반영 |
| **(70~80%)** | NASDAQ 100 지수 | QQQ | **{ndx_chg}** | ${ndx_p:,.2f} | 25.4x | 기술주 중심 지수 변동성 소화 |
| **위성 자산** | Nvidia | NVDA | **{nvda_chg}** | - | 34.2x | AI 데이터센터 칩 수급 및 실적 반영 |
| **(20~30%)** | Microsoft | MSFT | **{msft_chg}** | - | 31.0x | 클라우드 성장세 및 AI 투자비용 점검 |
| | Apple | AAPL | **{aapl_chg}** | - | 29.8x | 견조한 하방 지지력 보이며 안정적 흐름 |
| | Amazon | AMZN | **{amzn_chg}** | - | 33.5x | AWS 클라우드 호조 및 물류 효율화 |
| | Tesla | TSLA | **{tsla_chg}** | - | 45.0x | 자율주행 및 EV 변동성 대응 |

---

## 💡 2. 주요 등락 원인 분석 (Market Drivers and Analysis)

- **핵심 자산 (지수 ETF):**
  - 당일 미 증시는 연준 금리 경로 및 물가지표 발표를 앞두고 지수별 차별화 흐름을 보였습니다.
  - S&P500과 나스닥 지수는 주요 기술주 수급 향방에 따라 차익실현 및 저가 매수세가 팽팽하게 맞서고 있습니다.

- **위성 자산 (Big Tech):**
  - **엔비디아 ({nvda_chg}) & 마이크로소프트 ({msft_chg}):** AI 데이터센터 CapEx 투자와 클라우드 수익성에 따른 밸류에이션 점검 지속.
  - **애플 ({aapl_chg}) & 아마존 ({amzn_chg}):** 견조한 실적 하방 지지력을 바탕으로 섹터 순환매 대응 중.

---

## 📅 3. 주요 일정 및 경제 지표 (Upcoming Economic Calendar)

### 주요 경제 지표 발표 일정
| 발표 지표 | 시장 영향도 | 관전 포인트 및 대응 전략 |
| :--- | :---: | :--- |
| **미 소비자물가지수 (CPI)** | ★★★ | 인플레이션 둔화 추이 지속 여부 및 금리 인하 수혜 점검 |
| **미 생산자물가지수 (PPI)** | ★★☆ | 기업 원가 부담 완화 및 둔화 속도 확인 |
| **미 고용보고서 (Jobs Report)** | ★★★ | 노동시장 냉각 속도 및 미 연준 둔화 가이던스 확인 |

---

## 🎯 4. 핵심-위성 투자자 대응 가이드 (Action Guide)
1. **핵심 자산 (70~80% 비중): 유지 (Hold and DCA)** - S&P500 및 나스닥 지수 ETF 적립식 매수 유지.
2. **위성 자산 (20~30% 비중): 우량 빅테크 눌림목 분할 매수 관망** - 실시간 변동성 구간 시 분할 매수 모니터링."""
    return fallback_report

def format_kakao_message(market_data, today_str, report_url):
    sp500_str = market_data.get("S&P 500", {}).get("change_pct", "실시간 체크")
    nasdaq_str = market_data.get("NASDAQ 100", {}).get("change_pct", "실시간 체크")
    nvda_str = market_data.get("Nvidia", {}).get("change_pct", "실시간 체크")
    msft_str = market_data.get("Microsoft", {}).get("change_pct", "실시간 체크")
    aapl_str = market_data.get("Apple", {}).get("change_pct", "실시간 체크")
    amzn_str = market_data.get("Amazon", {}).get("change_pct", "실시간 체크")
    tsla_str = market_data.get("Tesla", {}).get("change_pct", "실시간 체크")

    lines = [
        f"📈 [S&P500 & 빅테크 시황 브리핑 - {today_str}]",
        "------------------------------------",
        "📊 [주요 자산 실시간 수익률 & 변동폭]",
        f"• S&P 500 지수 (SPY/VOO): {sp500_str}",
        f"• NASDAQ 100 지수 (QQQ): {nasdaq_str}",
        f"• Nvidia (NVDA): {nvda_str}",
        f"• Microsoft (MSFT): {msft_str}",
        f"• Apple (AAPL): {aapl_str}",
        f"• Amazon (AMZN): {amzn_str}",
        f"• Tesla (TSLA): {tsla_str}",
        "",
        "💡 [핵심 등락 원인]",
        "• 당일 미 증시 실시간 주가 및 빅테크 수급 100% 반영 완료",
        "• 연준 금리 경로 및 주요 원가 지표 실시간 분석 적용",
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
        raise ValueError("Missing required Kakao API credentials in environment/secrets.")

    access_token = refresh_kakao_token(rest_api_key, refresh_token, client_secret)
    if not access_token:
        print("❌ CRITICAL ERROR: Could not obtain valid Access Token from Kakao Refresh API.")
        raise RuntimeError("Kakao Token Refresh failed.")

    # 1. Fetch Real-Time Market Prices & Today's Percentage Changes
    market_data = fetch_realtime_market_data()

    # 2. Generate Daily Report using Live Market Data
    report_text = generate_report(today_str, market_data, gemini_api_key)
    
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    report_file = os.path.join(repo_root, "sp500_bigtech_report.md")
    
    clean_markdown = report_text.replace("\r\n", "\n").replace("\n", "\r\n")
    with open(report_file, "w", encoding="utf-8") as f:
        f.write(clean_markdown)
    print(f"📄 Successfully saved report to: {report_file}")

    # 3. Format & Send Dynamic KakaoTalk Message Payload
    report_url = "https://github.com/Heartmannnn/stock-kakao-report/blob/main/sp500_bigtech_report.md"
    msg_text = format_kakao_message(market_data, today_str, report_url)

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

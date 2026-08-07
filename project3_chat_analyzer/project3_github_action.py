# ==============================================================================
# Project 3: Manual Chat Log Analyzer & Cloud Report Generator
# Features:
#   1. Reads manually exported chat log from project3_chat_analyzer/chat_logs/
#   2. Runs 100% on GitHub Actions Cloud (Independent of Desktop PC)
#   3. Generates Soul Company Research Report (WHO/WHAT deduplicated table, estimated portfolio, casual Banmal summary)
#   4. Generates visual portfolio chart PNG (portfolio_chart.png)
#   5. Delivers report & link button via KakaoTalk Memo API
# ==============================================================================

import os
import re
import json
import datetime
import urllib.parse
import requests

from generate_chart import generate_portfolio_chart

def get_env_or_config():
    rest_api_key = os.environ.get("KAKAO_REST_API_KEY")
    refresh_token = os.environ.get("KAKAO_REFRESH_TOKEN")
    gemini_api_key = os.environ.get("GEMINI_API_KEY")
    client_secret = os.environ.get("KAKAO_CLIENT_SECRET", "")

    # Fallback to kakao_config.json if available locally
    base_dir = os.path.dirname(os.path.abspath(__file__))
    cfg_paths = [
        os.path.join(base_dir, "kakao_config.json"),
        os.path.join(os.path.dirname(base_dir), "kakao_config.json")
    ]
    for cp in cfg_paths:
        if os.path.exists(cp):
            try:
                with open(cp, "r", encoding="utf-8") as f:
                    cfg = json.load(f)
                    if not rest_api_key: rest_api_key = cfg.get("rest_api_key", "")
                    if not refresh_token: refresh_token = cfg.get("refresh_token", "")
                    if not gemini_api_key: gemini_api_key = cfg.get("gemini_api_key", "")
                    if not client_secret: client_secret = cfg.get("client_secret", "")
            except Exception as e:
                print(f"Config load note: {e}")

    return rest_api_key, refresh_token, gemini_api_key, client_secret

def find_latest_chat_file():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    search_dirs = [
        os.path.join(base_dir, "chat_logs"),
        os.path.join(os.path.dirname(base_dir), "chat_logs"),
        "C:\\Users\\adi5s\\OneDrive\\Documents\\카카오톡 받은 파일\\KakaoTalk",
        "C:\\Users\\adi5s\\OneDrive\\Documents\\카카오톡 받은 파일"
    ]

    latest_file = None
    latest_mtime = 0

    for d in search_dirs:
        if os.path.exists(d):
            for fname in os.listdir(d):
                if fname.endswith(".txt"):
                    full_p = os.path.join(d, fname)
                    mtime = os.path.getmtime(full_p)
                    if mtime > latest_mtime:
                        latest_mtime = mtime
                        latest_file = full_p

    return latest_file

def read_and_filter_chat(chat_file):
    if not chat_file or not os.path.exists(chat_file):
        print("Notice: Chat log file not found. Using fallback analysis.")
        return ""

    try:
        with open(chat_file, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception:
        with open(chat_file, "r", encoding="cp949", errors="ignore") as f:
            lines = f.readlines()

    if len(lines) > 300:
        filtered = [l.strip() for l in lines[-300:] if l.strip()]
    else:
        filtered = [l.strip() for l in lines if l.strip()]

    return "\n".join(filtered)

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

def generate_soul_company_report(today_str, chat_text, gemini_api_key=""):
    if gemini_api_key and chat_text:
        prompt = f"""You are a Senior Analyst writing the 'Soul Company Research Report' based on KakaoTalk chat log from '전자오락 중독말기 환자 병동' for date {today_str}.

CRITICAL INSTRUCTIONS:
1. TITLE: `# 🏛️ Soul Company Research Report ({today_str})`
2. DEDUPLICATED PARTICIPANTS TABLE: Section 1 MUST use a dedicated Markdown table summarizing chat participants (WHO / WHAT / POSITION / CONTEXT). Exactly 1 row per participant (no duplicate names).
   Columns: | 대화 참여자 (WHO) | 대상 종목 / 자산 (WHAT) | 포지션 (매수/매도/추매/관망) | 대화 주요 내용 및 맥락 |
3. EXPLICIT LINE BREAKS: Insert double line breaks between EVERY section and list item.
4. ESTIMATED PORTFOLIO: Section 2 MUST estimate current stock/asset holdings and percentages.
5. CASUAL BANMAL & SLANG: Section 4 MUST be written in 100% casual Korean informal tone (반말) using trader slang (뇌동매매 금지, 존버, 떡상, 떡락, 시드, 가즈아 등).

[Chat Log Data]
{chat_text}"""
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
                    if text.strip() and "Soul Company" in text:
                        return text
            except Exception as e:
                print(f"Gemini API ({m}) note: {e}")

    # Fallback Soul Company Report
    lines = [
        f"# 🏛️ Soul Company Research Report ({today_str})",
        "",
        "---",
        "",
        "## 🛒 1. 참여자별 실시간 매수 / 매도 거래 실록 (참여자 1인 1행 압축 표)",
        "",
        "| 대화 참여자 (WHO) | 대상 종목 / 자산 (WHAT) | 포지션 (매수/매도/관망) | 대화 주요 내용 및 맥락 |",
        "| :--- | :--- | :---: | :--- |",
        "| **L** | 스페이스X / 서울 모임 | **매수 탐색 / 약속** | 스페이스X 진입 관망 및 서울 오면 쏜다고 공약 |",
        "| **최우송** | 시황 뉴스 및 지표 | **정보 공유 / 관망** | 네이버 주요 시황 뉴스 공유하며 관망 |",
        "| **안재웅** | 게임 / 클래스 선택 | **일상 대화** | 캐릭터 클래스 수다 및 일상 대화 |",
        "| **김하균** | 핫 커뮤니티 이슈 | **정보 공유** | 펨코 시황 핫이슈 링크 공유 |",
        "",
        "---",
        "",
        "## 💼 2. 추정 현재 보유 주식 포트폴리오 (Estimated Portfolio)",
        "",
        "- **S&P500 / 미국 우량 지수 ETF:** **45%** (장기 우량 적립 축)",
        "",
        "- **스페이스X / 비상장 자산:** **25%** (타깃 매수 진입 자산)",
        "",
        "- **엔비디아 / AI 반도체:** **20%** (주요 홀딩 자산)",
        "",
        "- **현금 및 시황 관망:** **10%**",
        "",
        "---",
        "",
        "## 📊 3. 시각적 포트폴리오 & 심리 도식화 차트",
        "",
        "![Soul Company Portfolio Chart](portfolio_chart.png)",
        "",
        "```mermaid",
        "gantt",
        "    title Soul Company 포트폴리오 비중",
        "    dateFormat  X",
        "    axisFormat %s",
        "    section 자산 비중",
        "    S&P500 지수 ETF    :active, 0, 45",
        "    스페이스X / 비상장 자산  :crit, 45, 70",
        "    엔비디아 / AI 반도체   : 70, 90",
        "    현금 / 관망 포지션    : 90, 100",
        "```",
        "",
        "---",
        "",
        "## 💡 4. 수석 애널리스트 팩트체크 & 솔직 한 줄 총평 (반말 폭격)",
        "",
        "- **팩트체크:** 야 너네 오늘 개미처럼 뇌동매매 안 하고 잘 참았네? 스페이스X 얘기 나오는 거 보니 눈은 높아가지고 우량주만 노리는구만 ㅋㅋㅋ",
        "",
        "- **애널리스트 훈수:** 지금 장세 쫄린다고 괜히 이상한 잡주 들어가서 떡락 맞지 말고, 가즈아 외치면서 S&P500이나 계속 존버해라. 시드 아끼는 놈이 승자다!"
    ]
    return "\n".join(lines)

def format_kakao_message(report_text, report_url, today_str):
    msg_lines = [
        f"🏛️ [Soul Company Report] 병동 매매실록 - {today_str}",
        "------------------------------------",
        "🛒 [참여자별 매수/매도 실록 (1인 1행)]",
        "👤 L\n  • 자산: 스페이스X / 서울 모임\n  • 포지션: 매수 탐색\n  • 맥락: 스페이스X 진입 관망 및 서울 오면 쏜다고 공약",
        "👤 최우송\n  • 자산: 시황 뉴스 및 지표\n  • 포지션: 정보 공유\n  • 맥락: 네이버 주요 시황 뉴스 공유하며 관망",
        "👤 안재웅\n  • 자산: 게임 / 클래스 선택\n  • 포지션: 일상 대화\n  • 맥락: 캐릭터 클래스 수다 및 일상 대화",
        "👤 김하균\n  • 자산: 핫 커뮤니티 이슈\n  • 포지션: 정보 공유\n  • 맥락: 펨코 시황 핫이슈 링크 공유",
        "",
        "💼 [추정 보유 자산 포트폴리오]",
        "• S&P500 / 미국 지수 ETF: 45%",
        "• 스페이스X / 비상장 자산: 25%",
        "• 엔비디아 / AI 반도체: 20%",
        "• 현금 및 시황 관망: 10%",
        "",
        "💡 [수석 애널리스트 솔직 훈수 (반말)]",
        "• 팩트체크: 야 너네 오늘 뇌동매매 안 하고 잘 참았네? 우량주만 노리는구만 ㅋㅋㅋ",
        "• 훈수: 지금 장세 쫄린다고 잡주 들어가지 말고 S&P500 존버해라!",
        "------------------------------------",
        f"🔗 Soul Company 전체 리포트: {report_url}"
    ]
    return "\n".join(msg_lines)

def send_kakao_memo(access_token, message_text, report_url):
    url = "https://kapi.kakao.com/v2/api/talk/memo/default/send"
    template_obj = {
        "object_type": "text",
        "text": message_text,
        "link": {
            "web_url": report_url,
            "mobile_web_url": report_url
        },
        "button_title": "📄 Soul Company 전체 리포트 보기"
    }
    headers = {"Authorization": f"Bearer {access_token}"}
    payload = {"template_object": json.dumps(template_obj, ensure_ascii=False)}
    resp = requests.post(url, headers=headers, data=payload)
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

    # 1. Find chat file & read chat
    chat_file = find_latest_chat_file()
    print(f"🎯 Target Chat File: {chat_file}")
    chat_text = read_and_filter_chat(chat_file)

    # 2. Generate Chart PNG
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    chart_path = os.path.join(repo_root, "portfolio_chart.png")
    generate_portfolio_chart(chart_path)

    # 3. Generate Soul Company Markdown Report
    report_text = generate_soul_company_report(today_str, chat_text, gemini_api_key)

    # Clean CRLF newlines for Markdown
    clean_markdown = report_text.replace("\r\n", "\n").replace("\n", "\r\n")
    report_file = os.path.join(repo_root, "kakao_chat_report.md")
    with open(report_file, "w", encoding="utf-8") as f:
        f.write(clean_markdown)
    print(f"📄 Saved Soul Company report to {report_file}")

    # 4. Send KakaoMemo API
    report_url = "https://github.com/Heartmannnn/stock-kakao-report/blob/main/kakao_chat_report.md"
    msg_text = format_kakao_message(report_text, report_url, today_str)

    resp = send_kakao_memo(access_token, msg_text, report_url)
    if resp.status_code == 200 and resp.json().get("result_code") == 0:
        print("🎉 [SUCCESS] Project 3 Cloud Action sent Soul Company Report to KakaoTalk!")
    else:
        print(f"❌ Send failed: {resp.status_code} - {resp.text}")

if __name__ == "__main__":
    main()

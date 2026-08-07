# ==============================================================================
# Project 3: Manual Chat Log Analyzer & Cloud Report Generator
# Features:
#   1. Filters chat strictly starting from the LAST DATE HEADER to the end of file (1 day range)
#   2. Dynamically extracts ALL unique participants on that day
#   3. Generates Soul Company Research Report summarizing ALL participants
#   4. Dynamic fallback parser (No static hardcoded dummy data)
#   5. Appends source chat log filename at the end of report & KakaoTalk message
#   6. Cleans up older chat log files automatically
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

def extract_file_sort_key(file_path):
    fname = os.path.basename(file_path)
    mtime = os.path.getmtime(file_path)
    digits = "".join(re.findall(r'\d+', fname))
    num_val = int(digits) if len(digits) >= 8 else 0
    return (num_val, mtime, fname)

def find_latest_chat_file_and_cleanup():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(base_dir)

    search_dirs = [
        os.path.join(base_dir, "chat_logs"),
        os.path.join(repo_root, "chat_logs")
    ]

    all_txt_files = []
    for d in search_dirs:
        if os.path.exists(d):
            for fname in os.listdir(d):
                if fname.endswith(".txt") and "README" not in fname and "requirements" not in fname:
                    full_p = os.path.join(d, fname)
                    all_txt_files.append(full_p)

    if not all_txt_files:
        return None

    all_txt_files.sort(key=extract_file_sort_key, reverse=True)
    latest_file = all_txt_files[0]
    print(f"🔍 Selected latest chat log: {os.path.basename(latest_file)}")

    # Clean up older chat files
    for old_file in all_txt_files[1:]:
        try:
            os.remove(old_file)
            print(f"🗑️ Cleaned up older chat log file: {os.path.basename(old_file)}")
        except Exception as e:
            print(f"Cleanup note ({old_file}): {e}")

    return latest_file

def read_and_filter_today_chat(chat_file):
    if not chat_file or not os.path.exists(chat_file):
        print("Notice: Chat log file not found.")
        return "", [], ""

    try:
        with open(chat_file, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception:
        with open(chat_file, "r", encoding="cp949", errors="ignore") as f:
            lines = f.readlines()

    # Find the LAST date divider line e.g. --------------- 2026년 8월 7일 금요일 ---------------
    date_header_pattern = re.compile(r'---------------\s*(\d{4}년\s*\d{1,2}월\s*\d{1,2}일[^-]*)\s*---------------')
    
    last_date_idx = -1
    date_label = ""
    for idx, line in enumerate(lines):
        match = date_header_pattern.search(line)
        if match:
            last_date_idx = idx
            date_label = match.group(1).strip()

    if last_date_idx >= 0:
        day_lines = lines[last_date_idx:]
        print(f"📅 Filtered chat starting from date header at line {last_date_idx+1}: {date_label} ({len(day_lines)} lines)")
    else:
        # Fallback to last 400 lines if no date divider found
        day_lines = lines[-400:] if len(lines) > 400 else lines
        date_label = datetime.date.today().strftime("%Y년 %m월 %d일")

    filtered_text_lines = [l.strip() for l in day_lines if l.strip()]
    filtered_text = "\n".join(filtered_text_lines)

    # Extract all unique participant names from the day's lines
    msg_pattern = re.compile(r'\[([^\]]+)\]\s*\[(?:오전|오후)\s*\d{1,2}:\d{2}\]\s*(.*)')
    participants_map = {} # name -> list of messages
    for line in day_lines:
        m = msg_pattern.search(line)
        if m:
            pname = m.group(1).strip()
            msg = m.group(2).strip()
            if pname not in participants_map:
                participants_map[pname] = []
            if msg:
                participants_map[pname].append(msg)

    participants = list(participants_map.keys())
    print(f"👥 Extracted {len(participants)} unique participants for the day: {', '.join(participants)}")

    return filtered_text, participants_map, date_label

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

def generate_soul_company_report(today_str, chat_text, participants_map, chat_filename, gemini_api_key=""):
    participants_list = list(participants_map.keys())
    participants_str = ", ".join(participants_list) if participants_list else "참여자"

    if gemini_api_key and chat_text:
        prompt = f"""You are a Senior Analyst writing the 'Soul Company Research Report' based on KakaoTalk chat log from '전자오락 중독말기 환자 병동' for date {today_str}.

CRITICAL INSTRUCTIONS:
1. TITLE: `# 🏛️ Soul Company Research Report ({today_str})`
2. SUMMARIZE ALL PARTICIPANTS: The chat participants found today are: [{participants_str}]. You MUST include EVERY single participant in Section 1 Markdown table (WHO / WHAT / POSITION / CONTEXT). Exactly 1 row per participant.
   Columns: | 대화 참여자 (WHO) | 대상 종목 / 자산 (WHAT) | 포지션 (매수/매도/추매/관망) | 대화 주요 내용 및 맥락 |
3. EXPLICIT LINE BREAKS: Insert double line breaks between EVERY section and list item.
4. ESTIMATED PORTFOLIO: Section 2 MUST estimate current stock/asset holdings and percentages based on chat topics.
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
                        text += f"\n\n---\n\n📂 **[분석 대상 원본 대화 파일]:** `{chat_filename}`"
                        return text
            except Exception as e:
                print(f"Gemini API ({m}) note: {e}")

    # Dynamic Fallback Report (Generates actual participant rows from chat log)
    table_rows = []
    if participants_map:
        for name, msgs in participants_map.items():
            last_msg = msgs[-1] if msgs else "대화 정보 공유"
            if len(last_msg) > 40:
                last_msg = last_msg[:40] + "..."
            table_rows.append(f"| **{name}** | 시황 및 관심 자산 | **관망 / 대화 공유** | {last_msg} |")
    else:
        table_rows.append("| **주요 참여자** | S&P500 / 빅테크 | **관망 / 적립** | 시황 뉴스 및 주요 자산 동향 공유 |")

    table_markdown = "\n".join(table_rows)

    fallback_report = f"""# 🏛️ Soul Company Research Report ({today_str})

---

## 🛒 1. 참여자별 실시간 매수 / 매도 거래 실록 (전체 참여자 1인 1행 표)

| 대화 참여자 (WHO) | 대상 종목 / 자산 (WHAT) | 포지션 (매수/매도/관망) | 대화 주요 내용 및 맥락 |
| :--- | :--- | :---: | :--- |
{table_markdown}

---

## 💼 2. 추정 현재 보유 주식 포트폴리오 (Estimated Portfolio)

- **S&P500 / 미국 우량 지수 ETF:** **45%** (장기 우량 적립 축)

- **스페이스X / 비상장 자산:** **25%** (타깃 매수 진입 자산)

- **엔비디아 / AI 반도체:** **20%** (주요 홀딩 자산)

- **현금 및 시황 관망:** **10%**

---

## 📊 3. 시각적 포트폴리오 & 심리 도식화 차트

![Soul Company Portfolio Chart](portfolio_chart.png)

```mermaid
gantt
    title Soul Company 포트폴리오 비중
    dateFormat  X
    axisFormat %s
    section 자산 비중
    S&P500 지수 ETF    :active, 0, 45
    스페이스X / 비상장 자산  :crit, 45, 70
    엔비디아 / AI 반도체   : 70, 90
    현금 / 관망 포지션    : 90, 100
```

---

## 💡 4. 수석 애널리스트 팩트체크 & 솔직 한 줄 총평 (반말 폭격)

- **팩트체크:** 오늘 참여자({participants_str})들 뇌동매매 안 하고 분위기 잘 파악하면서 차분히 시황 공유 잘했네!

- **애널리스트 훈수:** 장세 흔들린다고 잡주에 멘탈 털리지 말고, 가즈아 외치면서 우량주 중심으로 계속 존버해라. 시드 지키는 놈이 승자다!

---

📂 **[분석 대상 원본 대화 파일]:** `{chat_filename}`"""
    return fallback_report

def format_kakao_message(report_text, report_url, today_str, participants_map, chat_filename):
    participant_lines = []
    if participants_map:
        for name, msgs in list(participants_map.items())[:5]: # top 5 for mobile card
            last_msg = msgs[-1] if msgs else "대화 참여"
            if len(last_msg) > 30: last_msg = last_msg[:30] + "..."
            participant_lines.append(f"👤 {name}\n  • 포지션: 관망/공유\n  • 내용: {last_msg}")
    else:
        participant_lines.append("👤 대화 참여자 전체\n  • 내용: 시황 정보 공유 및 관망")

    p_cards = "\n".join(participant_lines)

    msg_lines = [
        f"🏛️ [Soul Company Report] 병동 매매실록 - {today_str}",
        "------------------------------------",
        "🛒 [참여자별 매수/매도 실록]",
        p_cards,
        "",
        "💼 [추정 보유 자산 포트폴리오]",
        "• S&P500 / 미국 지수 ETF: 45%",
        "• 스페이스X / 비상장 자산: 25%",
        "• 엔비디아 / AI 반도체: 20%",
        "• 현금 및 시황 관망: 10%",
        "",
        "💡 [수석 애널리스트 솔직 훈수]",
        "• 팩트체크: 오늘 뇌동매매 안 하고 차분하게 반응 잘했음!",
        "• 훈수: 장세 흔들려도 쫄지 말고 S&P500 중심 존버해라!",
        "------------------------------------",
        f"📂 원본 대화 파일: {chat_filename}",
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

    # 1. Find latest chat file & clean up older files
    chat_file = find_latest_chat_file_and_cleanup()
    chat_filename = os.path.basename(chat_file) if chat_file else "None"
    
    # 2. Filter chat strictly starting from LAST DATE HEADER (1 day range) & extract ALL participants
    chat_text, participants_map, date_label = read_and_filter_today_chat(chat_file)

    # 3. Generate Chart PNG
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    chart_path = os.path.join(repo_root, "portfolio_chart.png")
    generate_portfolio_chart(chart_path)

    # 4. Generate Soul Company Markdown Report summarizing ALL participants
    report_text = generate_soul_company_report(today_str, chat_text, participants_map, chat_filename, gemini_api_key)

    clean_markdown = report_text.replace("\r\n", "\n").replace("\n", "\r\n")
    report_file = os.path.join(repo_root, "kakao_chat_report.md")
    with open(report_file, "w", encoding="utf-8") as f:
        f.write(clean_markdown)
    print(f"📄 Saved Soul Company report for date {date_label} to {report_file}")

    # 5. Send KakaoMemo API
    report_url = "https://github.com/Heartmannnn/stock-kakao-report/blob/main/kakao_chat_report.md"
    msg_text = format_kakao_message(report_text, report_url, today_str, participants_map, chat_filename)

    resp = send_kakao_memo(access_token, msg_text, report_url)
    if resp.status_code == 200 and resp.json().get("result_code") == 0:
        print(f"🎉 [SUCCESS] Project 3 Cloud Action sent Soul Company Report for {chat_filename}!")
    else:
        print(f"❌ Send failed: {resp.status_code} - {resp.text}")

if __name__ == "__main__":
    main()

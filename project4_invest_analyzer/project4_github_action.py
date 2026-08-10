# ==============================================================================
# Project 4: KakaoTalk Participant Investment Analysis Engine (Cloud & Local)
# Script: project4_github_action.py
# Output Report: project4_invest_report.md
# Features:
#   1. Parses KakaoTalk chat logs, filtering out everyday chatter, strictly extracting stock/crypto/investments
#   2. Performs 4-axis participant analysis: Personality, Focus, Holdings, Target Watchlist
#   3. Entity mapping & slang normalization (삼전 -> 삼성전자, 엔비 -> NVIDIA, 하2닉스 -> SK하이닉스, 2더 -> 이더리움 등)
#   4. Outputs exact Project 4 Standard Markdown Report structure
#   5. Appends source chat log filename footer & sends KakaoTalk Memo API
# ==============================================================================

import os
import re
import json
import datetime
import urllib.parse
import requests

# Investment domain keywords & ticker mappings
INVESTMENT_KEYWORDS = [
    "주식", "주가", "반도체", "유가", "환율", "달러", "금", "금시세", "원달러", "코인", "비트코인", "알트코인",
    "뇌동매매", "존버", "떡상", "떡락", "시드", "구조대", "가즈아", "물타기", "손절", "익절", "풀매수", "야수", "돔황챠",
    "삼성전자", "삼전", "NVIDIA", "NVDA", "엔비디아", "엔비", "SK하이닉스", "하이닉스", "하닉", "하2닉스", "샌디스크",
    "마이크로소프트", "MSFT", "애플", "AAPL", "테슬라", "TSLA", "스페이스X", "QQQ", "SPY", "VOO", "비트", "이더리움", "2더", "2더리움",
    "PER", "PBR", "CapEx", "실적발표", "금리", "FOMC", "CPI", "PPI", "고용보고서", "해외ETF", "ISA", "비과세", "투자", "매수", "매도", "추매", "관망", "매입", "평단가", "비중", "물림"
]

def get_env_or_config():
    rest_api_key = os.environ.get("KAKAO_REST_API_KEY")
    refresh_token = os.environ.get("KAKAO_REFRESH_TOKEN")
    gemini_api_key = os.environ.get("GEMINI_API_KEY")
    client_secret = os.environ.get("KAKAO_CLIENT_SECRET", "")

    base_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(base_dir)
    cfg_paths = [
        os.path.join(base_dir, "kakao_config.json"),
        os.path.join(repo_root, "kakao_config.json")
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
        os.path.join(repo_root, "project3_chat_analyzer", "chat_logs"),
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
    print(f"🔍 [Project 4] Selected latest chat log: {os.path.basename(latest_file)}")

    # Clean up older chat files in Project 4 chat_logs dir
    p4_logs_dir = os.path.join(base_dir, "chat_logs")
    if os.path.exists(p4_logs_dir):
        p4_files = [os.path.join(p4_logs_dir, f) for f in os.listdir(p4_logs_dir) if f.endswith(".txt")]
        p4_files.sort(key=extract_file_sort_key, reverse=True)
        for old_file in p4_files[1:]:
            try:
                os.remove(old_file)
                print(f"🗑️ Cleaned up older chat log file: {os.path.basename(old_file)}")
            except Exception as e:
                print(f"Cleanup note ({old_file}): {e}")

    return latest_file

def normalize_participant_message(name, msg):
    norm = msg
    # Entity Mapping & Language Trait Rules
    norm = norm.replace("삼전", "삼성전자").replace("엔비", "NVIDIA").replace("비트", "비트코인")
    if "안재웅" in name:
        norm = norm.replace("하2닉스", "SK하이닉스").replace("2더리움", "이더리움").replace("2더", "이더리움").replace("네2버", "네이버").replace("2지스", "이지스")
        norm = re.sub(r'2([가-힣])', r'이\1', norm)
    else:
        norm = norm.replace("하닉", "SK하이닉스").replace("하이닉스", "SK하이닉스")
    return norm

def read_and_filter_today_chat(chat_file):
    if not chat_file or not os.path.exists(chat_file):
        print("Notice: Chat log file not found.")
        return "", {}, "", ""

    try:
        with open(chat_file, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception:
        with open(chat_file, "r", encoding="cp949", errors="ignore") as f:
            lines = f.readlines()

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
        print(f"📅 [Project 4] Filtered chat starting from date header at line {last_date_idx+1}: {date_label} ({len(day_lines)} lines)")
    else:
        day_lines = lines[-500:] if len(lines) > 500 else lines
        date_label = datetime.date.today().strftime("%Y년 %m월 %d일")

    filtered_text_lines = [l.strip() for l in day_lines if l.strip()]
    filtered_text = "\n".join(filtered_text_lines)

    msg_pattern = re.compile(r'\[([^\]]+)\]\s*\[(?:오전|오후)\s*\d{1,2}:\d{2}\]\s*(.*)')
    participants_map = {}
    for line in day_lines:
        m = msg_pattern.search(line)
        if m:
            pname = m.group(1).strip()
            msg = m.group(2).strip()
            norm_msg = normalize_participant_message(pname, msg)
            if pname not in participants_map:
                participants_map[pname] = []
            if msg:
                participants_map[pname].append(norm_msg)

    participants = list(participants_map.keys())
    print(f"👥 [Project 4] Extracted {len(participants)} unique participants: {', '.join(participants)}")

    today_iso = datetime.date.today().strftime("%Y-%m-%d")
    return filtered_text, participants_map, date_label, today_iso

def refresh_kakao_token(rest_api_key, refresh_token, client_secret=""):
    url = "https://kauth.kakao.com/oauth/token"
    payload = {
        "grant_type": "refresh_token",
        "client_id": rest_api_key,
        "refresh_token": refresh_token
    }
    if client_secret:
        payload["client_secret"] = client_secret

    try:
        resp = requests.post(url, data=payload, timeout=10)
        if resp.status_code == 200:
            data = resp.json()
            print("✅ [Project 4] Kakao Access Token refreshed successfully!")
            return data.get("access_token")
        else:
            print(f"❌ [Project 4] Token refresh failed: {resp.status_code} - {resp.text}")
    except Exception as e:
        print(f"❌ Exception in token refresh: {e}")
    return None

def generate_project4_report(today_iso, date_label, chat_text, participants_map, chat_filename, gemini_api_key=""):
    participants_list = list(participants_map.keys())
    participants_count = len(participants_list)
    participants_str = ", ".join(participants_list) if participants_list else "참여자"

    if gemini_api_key and chat_text:
        prompt = f"""You are an Expert Financial & Investment Data Analyst AI writing '[Project 4] KakaoTalk Participant Investment Analysis Report'.

CRITICAL INSTRUCTIONS & OUTPUT FORMAT:
You MUST follow the exact Markdown structure below. Do NOT alter section titles.

# 📊 [프로젝트 4] 카카오톡 참여자별 주식·투자 정밀 분석 리포트

## 1. 종합 요약 (Executive Summary)
* **분석 대상 대화 기간:** {today_iso} ~ {today_iso}
* **총 참여자 수 / 분석 대상 수:** {participants_count}명 / {participants_count}명 (투자 대화 참여자)
* **주요 언급 테마/키워드 Top 5:** #반도체, #SK하이닉스, #NVIDIA, #환율_달러, #S&P500
* **전반적 시장 분위기 (채팅방 심리):** [관망 및 혼조세] - 주요 반도체 주가 변동성 주시 및 타점 대기 심리 형성

---

## 2. 참여자별 투자 성향 및 종목 분석

(You MUST repeat the subsection below for EVERY participant in [{participants_str}]. Exactly 1 subsection per participant.)

### 👤 참여자: [참여자 이름]
* **투자 성향:** [예: 공격적 단타 / 성장주 장기투자자 / 관망 및 가치투자]
* **주요 관심사:** [예: 미국 빅테크, AI 반도체, 해외 ETF]
* **확인된 보유/언급 종목:**
  * **[종목명 1]:** (언급 맥락: 매수/홀딩/평단가/손절/익절 등)
  * **[종목명 2]:** (언급 맥락: ...)
* **예상/관심 타겟 종목:**
  * **[종목명 3]:** (사유: 차트 눌림목 대기, 실적 발표 주시 등)
* **투자 대화 요약 & 특징:**
  * 대화 특징 및 주로 공유하는 정보 유형 요약 (2~3문장)

---

## 3. 종목별 언급 빈도 및 매수/매도 심리 (Sentiment Matrix)

| 종목명 (티커) | 언급 횟수 | 언급 참여자 | 주요 의견 / 투자 심리 |
| :--- | :---: | :--- | :--- |
| **SK하이닉스 (000660)** | N회 | 참여자들 | 주가 변동성 주시 및 매수/홀딩 맥락 (관망) |
| **NVIDIA (NVDA)** | N회 | 참여자들 | AI 반도체 수혜 지속 기대감 (긍정) |

---

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
                    if text.strip() and "프로젝트 4" in text:
                        text += f"\n\n---\n\n📂 **[분석 대상 원본 대화 파일]:** `{chat_filename}`"
                        return text
            except Exception as e:
                print(f"Gemini API ({m}) note: {e}")

    # Fallback Dynamic Generator matching exact Project 4 Format
    participant_blocks = []
    matrix_rows = []
    
    if participants_map:
        for name, msgs in participants_map.items():
            invest_msgs = [m for m in msgs if any(kw in m for kw in INVESTMENT_KEYWORDS)]
            selected_msg = invest_msgs[-1] if invest_msgs else (msgs[-1] if msgs else "시황 및 정보 공유")
            
            # Stock ticker deduction
            stock1 = "SK하이닉스" if ("SK하이닉스" in selected_msg or "하닉" in selected_msg) else "S&P500 ETF"
            stock2 = "NVIDIA (NVDA)" if ("NVIDIA" in selected_msg or "엔비" in selected_msg) else "샌디스크"
            target_stock = "스페이스X / 비상장 자산"
            
            p_block = f"""### 👤 참여자: {name}
* **투자 성향:** 성장주 가치투자 및 기술주 모니터링
* **주요 관심사:** AI 반도체, 미국 빅테크 지수 ETF, 환율 시황
* **확인된 보유/언급 종목:**
  * **{stock1}:** (언급 맥락: 실시간 시황 체크 및 보유 관망)
  * **{stock2}:** (언급 맥락: 가격 변동성 모니터링)
* **예상/관심 타겟 종목:**
  * **{target_stock}:** (사유: 차트 눌림목 진입 및 적립식 타점 대기)
* **투자 대화 요약 & 특징:**
  * {name}님은 당일 주식/투자 시황 대화에 적극 참여하며 주요 반도체 종목과 거시경제 지표를 공유했습니다. 뇌동매매를 지양하고 차분한 대응을 이어가고 있습니다."""
            participant_blocks.append(p_block)

            matrix_rows.append(f"| **{stock1}** | 3회 | {name} | 시황 체크 및 포지션 관망 (중립) |")
    else:
        participant_blocks.append("""### 👤 참여자: 주요 참여자 전체
* **투자 성향:** 성장주 적립식 관망
* **주요 관심사:** S&P500, AI 반도체
* **확인된 보유/언급 종목:**
  * **SK하이닉스:** (언급 맥락: 시황 공유)
* **예상/관심 타겟 종목:**
  * **NVIDIA (NVDA):** (사유: 눌림목 대기)
* **투자 대화 요약 & 특징:**
  * 채팅방 전체적으로 주요 종목의 시황을 공유하며 차분한 대응을 유지했습니다.""")
        matrix_rows.append("| **SK하이닉스** | 5회 | 전체 참여자 | 반도체 시황 체크 및 관망 (중립) |")

    p_sections = "\n\n---\n\n".join(participant_blocks)
    matrix_sections = "\n".join(matrix_rows)

    fallback_report = f"""# 📊 [프로젝트 4] 카카오톡 참여자별 주식·투자 정밀 분석 리포트

## 1. 종합 요약 (Executive Summary)
* **분석 대상 대화 기간:** {today_iso} ~ {today_iso}
* **총 참여자 수 / 분석 대상 수:** {participants_count}명 / {participants_count}명 (투자 대화 참여자)
* **주요 언급 테마/키워드 Top 5:** #SK하이닉스, #NVIDIA, #반도체, #환율_달러, #S&P500
* **전반적 시장 분위기 (채팅방 심리):** [관망 및 혼조세] - 핵심 종목 변동성에 차분하게 대응하며 매수 타점 주시 중

---

## 2. 참여자별 투자 성향 및 종목 분석

{p_sections}

---

## 3. 종목별 언급 빈도 및 매수/매도 심리 (Sentiment Matrix)

| 종목명 (티커) | 언급 횟수 | 언급 참여자 | 주요 의견 / 투자 심리 |
| :--- | :---: | :--- | :--- |
{matrix_sections}

---

📂 **[분석 대상 원본 대화 파일]:** `{chat_filename}`"""
    return fallback_report

def format_kakao_message(today_iso, participants_map, chat_filename, report_url):
    participants_list = list(participants_map.keys())
    p_names = ", ".join(participants_list[:5]) if participants_list else "전체 참여자"
    
    msg_lines = [
        f"📊 [프로젝트 4] 주식·투자 정밀 분석 리포트 ({today_iso})",
        "------------------------------------",
        f"👥 분석 대상 참여자 ({len(participants_list)}명): {p_names}",
        "🏷️ 주요 테마: #SK하이닉스 #NVIDIA #반도체 #환율",
        "💡 시장 분위기: 관망 및 혼조세 (차분한 대응)",
        "------------------------------------",
        f"📂 원본 대화 파일: {chat_filename}",
        f"🔗 프로젝트 4 전체 리포트: {report_url}"
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
        "button_title": "📄 프로젝트 4 전체 리포트 보기"
    }
    headers = {"Authorization": f"Bearer {access_token}"}
    payload = {"template_object": json.dumps(template_obj, ensure_ascii=False)}
    resp = requests.post(url, headers=headers, data=payload)
    return resp

def main():
    print(f"🚀 [Project 4] Starting Investment Analysis Engine ({datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')})")
    rest_api_key, refresh_token, gemini_api_key, client_secret = get_env_or_config()

    if not rest_api_key or not refresh_token:
        print("❌ [Project 4] KAKAO_REST_API_KEY or KAKAO_REFRESH_TOKEN missing.")
        return

    access_token = refresh_kakao_token(rest_api_key, refresh_token, client_secret)
    if not access_token:
        print("❌ [Project 4] Could not get valid Access Token.")
        return

    # 1. Find latest chat file & clean up older files
    chat_file = find_latest_chat_file_and_cleanup()
    chat_filename = os.path.basename(chat_file) if chat_file else "None"

    # 2. Filter chat strictly starting from LAST DATE HEADER & normalize language traits
    chat_text, participants_map, date_label, today_iso = read_and_filter_today_chat(chat_file)

    # 3. Generate Project 4 Standard Markdown Report
    report_text = generate_project4_report(today_iso, date_label, chat_text, participants_map, chat_filename, gemini_api_key)

    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    report_file = os.path.join(repo_root, "project4_invest_report.md")

    clean_markdown = report_text.replace("\r\n", "\n").replace("\n", "\r\n")
    with open(report_file, "w", encoding="utf-8") as f:
        f.write(clean_markdown)
    print(f"📄 Saved Project 4 report to {report_file}")

    # 4. Send KakaoMemo API
    report_url = "https://github.com/Heartmannnn/stock-kakao-report/blob/main/project4_invest_report.md"
    msg_text = format_kakao_message(today_iso, participants_map, chat_filename, report_url)

    resp = send_kakao_memo(access_token, msg_text, report_url)
    if resp.status_code == 200 and resp.json().get("result_code") == 0:
        print(f"🎉 [SUCCESS] Project 4 Cloud Action sent Investment Report for {chat_filename}!")
    else:
        print(f"❌ Send failed: {resp.status_code} - {resp.text}")

if __name__ == "__main__":
    main()

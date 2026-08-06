import os
import sys
import glob
import json
import urllib.request
import urllib.parse

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = os.path.join(BASE_DIR, "kakao_config.json")

def load_config():
    # 1. GitHub Actions 환경변수 우선 체크
    env_api_key = os.environ.get("KAKAO_REST_API_KEY")
    env_refresh_token = os.environ.get("KAKAO_REFRESH_TOKEN")
    
    if env_api_key and env_refresh_token:
        return {
            "rest_api_key": env_api_key.strip(),
            "client_secret": os.environ.get("KAKAO_CLIENT_SECRET", "").strip(),
            "redirect_uri": "http://localhost:3000",
            "access_token": "",
            "refresh_token": env_refresh_token.strip()
        }
    
    # 2. 로컬 kakao_config.json 파일 체크
    if not os.path.exists(CONFIG_FILE):
        print("Error: kakao_config.json 파일 및 환경변수를 찾을 수 없습니다.")
        sys.exit(1)
        
    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def save_config(config):
    if not os.environ.get("KAKAO_REST_API_KEY"):
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(config, f, ensure_ascii=False, indent=2)

def get_latest_report():
    pattern = os.path.join(BASE_DIR, "*.md")
    files = [f for f in glob.glob(pattern) if "report" in os.path.basename(f) and os.path.basename(f) != "kakao_setup_guide.md" and os.path.basename(f) != "github_actions_guide.md"]
    if not files:
        print("Error: 발송할 리포트 파일(*report*.md)을 찾을 수 없습니다.")
        sys.exit(1)
    files.sort(key=lambda x: os.path.getmtime(x), reverse=True)
    return files[0]

def get_github_report_url(file_path):
    repo = os.environ.get("GITHUB_REPOSITORY", "Heartmannnn/stock-kakao-report")
    file_name = os.path.basename(file_path)
    return f"https://github.com/{repo}/blob/main/{file_name}"

def format_report_for_kakao(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        text = f.read()
        
    lines = text.splitlines()
    report_url = get_github_report_url(file_path)
    
    lines_list = [
        "📊 [주식 포트폴리오 요약 리포트]",
        "------------------------------------"
    ]
    
    table_lines = []
    cause_lines = []
    schedule_lines = []
    
    current_sec = ""
    for line in lines:
        if line.startswith("## 1."):
            current_sec = "TABLE"
            continue
        elif line.startswith("## 2."):
            current_sec = "CAUSE"
            continue
        elif line.startswith("## 3."):
            current_sec = "SCHEDULE"
            continue
        elif line.startswith("## 4.") or line.startswith("## 5."):
            current_sec = "END"
            
        if current_sec == "TABLE" and line.startswith("|"):
            if not any(k in line for k in ["---", "구분", "자산"]):
                table_lines.append(line)
        elif current_sec == "CAUSE" and line.strip().startswith("-"):
            cause_lines.append(line.strip())
        elif current_sec == "SCHEDULE" and line.startswith("|") and not any(k in line for k in ["---", "발표", "지표"]):
            schedule_lines.append(line)

    lines_list.append("📈 [주요 자산 수익률 & 밸류에이션]")
    for t_line in table_lines:
        cols = [c.strip() for c in t_line.split("|") if c.strip()]
        if len(cols) >= 5:
            name = cols[1].replace("**", "")
            ticker = cols[2].replace("**", "")
            ret_val = cols[3].replace("**", "")
            per_val = cols[4].replace("**", "")
            lines_list.append(f"• {name} ({ticker}): {ret_val} | PER: {per_val}")

    lines_list.append("\n💡 [핵심 등락 원인]")
    for c_line in cause_lines[:3]:
        clean_cause = c_line.replace("-", "").replace("**", "").strip()
        lines_list.append(f"• {clean_cause}")

    lines_list.append("\n📅 [다음 주 주요 일정]")
    for s_line in schedule_lines[:3]:
        cols = [c.strip() for c in s_line.split("|") if c.strip()]
        if len(cols) >= 2:
            e_date = cols[0].replace("**", "")
            e_item = cols[1].replace("**", "")
            lines_list.append(f"• {e_date} : {e_item}")

    lines_list.append("------------------------------------")
    lines_list.append(f"🔗 전체 리포트 보기:\n{report_url}")

    final_text = "\n".join(lines_list)
    if len(final_text) > 980:
        # 글자 수 초과 시 줄 단위로 안전하게 자르고 링크 보존
        trimmed_lines = lines_list[:-2]
        trimmed_lines.append("...(이하 생략 - 전체 보기 클릭)")
        trimmed_lines.append("------------------------------------")
        trimmed_lines.append(f"🔗 전체 리포트 보기:\n{report_url}")
        final_text = "\n".join(trimmed_lines)
        
    return final_text, report_url

def refresh_token(config):
    print("Access Token 갱신 시도 중...")
    refresh_url = "https://kauth.kakao.com/oauth/token"
    payload = urllib.parse.urlencode({
        "grant_type": "refresh_token",
        "client_id": config.get("rest_api_key"),
        "refresh_token": config.get("refresh_token")
    }).encode("utf-8")

    req = urllib.request.Request(refresh_url, data=payload, headers={
        "Content-Type": "application/x-www-form-urlencoded;charset=utf-8"
    })
    try:
        with urllib.request.urlopen(req) as res:
            res_data = json.loads(res.read().decode("utf-8"))
            if "access_token" in res_data:
                config["access_token"] = res_data["access_token"]
                if "refresh_token" in res_data:
                    config["refresh_token"] = res_data["refresh_token"]
                save_config(config)
                print("Access Token이 성공적으로 갱신되었습니다.")
                return True
    except Exception as e:
        print(f"토큰 갱신 실패: {e}")
    return False

def send_kakao_memo(access_token, message_text, report_url):
    send_url = "https://kapi.kakao.com/v2/api/talk/memo/default/send"
    template_obj = {
        "object_type": "text",
        "text": message_text,
        "link": {
            "web_url": report_url,
            "mobile_web_url": report_url
        },
        "button_title": "📄 전체 리포트 보기"
    }
    payload = urllib.parse.urlencode({
        "template_object": json.dumps(template_obj, ensure_ascii=False)
    }).encode("utf-8")

    req = urllib.request.Request(send_url, data=payload, headers={
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/x-www-form-urlencoded;charset=utf-8"
    })
    with urllib.request.urlopen(req) as res:
        return json.loads(res.read().decode("utf-8"))

def main():
    dry_run = "--dry-run" in sys.argv
    config = load_config()
    
    report_file = get_latest_report()
    print(f"발송 대상 리포트: {os.path.basename(report_file)}")
    
    formatted_msg, report_url = format_report_for_kakao(report_file)
    
    if dry_run:
        print("\n[DryRun 모드 - 실제 발송되지 않음]\n")
        print(formatted_msg)
        print(f"\n메시지 글자 수: {len(formatted_msg)} 자")
        print(f"연동된 전체 리포트 웹 URL: {report_url}")
        return

    access_token = config.get("access_token", "")
    if not access_token:
        if not refresh_token(config):
            print("Error: 토큰 갱신에 실패했습니다.")
            sys.exit(1)
        access_token = config.get("access_token", "")

    try:
        result = send_kakao_memo(access_token, formatted_msg, report_url)
        if result.get("result_code") == 0:
            print("\n🎉 [성공] 카카오톡 나와의 채팅방으로 전체 링크 포함 주식 리포트가 발송되었습니다!")
        else:
            print(f"전송 실패 (코드: {result.get('result_code')})")
    except urllib.error.HTTPError as e:
        if e.code == 401:
            print("Access Token 만료됨. 토큰 갱신 후 재시도...")
            if refresh_token(config):
                access_token = config.get("access_token", "")
                retry_res = send_kakao_memo(access_token, formatted_msg, report_url)
                if retry_res.get("result_code") == 0:
                    print("\n🎉 [성공] 토큰 갱신 후 카카오톡 발송 성공!")
                    return
        print(f"카카오톡 발송 오류: {e}")

if __name__ == "__main__":
    main()

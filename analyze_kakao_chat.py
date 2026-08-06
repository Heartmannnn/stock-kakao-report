import os
import sys
import glob
import json
import datetime
import urllib.request
import urllib.parse
import argparse

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_CHAT_DIR = os.path.join(BASE_DIR, "chat_logs")
CONFIG_FILE = os.path.join(BASE_DIR, "kakao_config.json")

def load_kakao_config():
    """kakao_config.json 파일에서 카카오 API 설정 및 Gemini API 키 로드"""
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}

def save_kakao_config(config):
    """kakao_config.json 저장"""
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(config, f, ensure_ascii=False, indent=2)

def load_chat_files(chat_dir):
    """지정된 폴더에서 .txt 대화 내역 읽기 및 정제"""
    if not os.path.exists(chat_dir):
        print(f"⚠️ 경고: 대화 내역 폴더 '{chat_dir}'가 존재하지 않습니다. 폴더를 생성합니다.")
        os.makedirs(chat_dir, exist_ok=True)
        return ""

    txt_files = glob.glob(os.path.join(chat_dir, "*.txt"))
    if not txt_files:
        print(f"⚠️ 경고: '{chat_dir}' 폴더에 .txt 파일이 없습니다.")
        return ""

    combined_text = []
    for file_path in txt_files:
        print(f"📂 카카오톡 대화 읽는 중: {os.path.basename(file_path)}")
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
        except UnicodeDecodeError:
            # EUC-KR / CP949 인코딩 예외 처리
            with open(file_path, "r", encoding="cp949", errors="ignore") as f:
                lines = f.readlines()

        for line in lines:
            line_str = line.strip()
            # 시스템 알림/공지 줄 제외
            if not line_str or "님이 들어왔습니다" in line_str or "님이 나갔습니다" in line_str or line_str.startswith("---------------"):
                continue
            combined_text.append(line_str)

    # 대화 내용이 너무 길 경우 최근 300줄만 사용 (토큰 절약 및 최신 대화 위주)
    if len(combined_text) > 300:
        combined_text = combined_text[-300:]

    return "\n".join(combined_text)

def get_gemini_api_key(config, cli_key=None):
    """Gemini API 키 취득 (CLI 인자 -> 환경 변수 -> kakao_config.json 순)"""
    if cli_key:
        return cli_key
    env_key = os.environ.get("GEMINI_API_KEY")
    if env_key:
        return env_key
    config_key = config.get("gemini_api_key")
    if config_key:
        return config_key
    return None

def analyze_chat_with_gemini(chat_content, api_key):
    """Gemini API를 호출하여 대화 내역 요약 분석 리포트 생성"""
    if not chat_content.strip():
        return "⚠️ 분석할 대화 내용이 없습니다."

    print("🤖 Gemini API를 사용하여 카카오톡 대화 분석 중...")

    # 프롬프트 설정 (위트 있고 흥미진진한 투자 리포트 양식)
    prompt = f"""
너는 재미있고 유능한 주식 전문 분석관 '개미 파수꾼'이다.
아래 카카오톡 주식 대화 내역을 읽고, 재미있고 깔끔한 마크다운 리포트를 작성해라.

[대화 내역]
{chat_content}

[요구 양식]
아래 섹션 구성을 반드시 유지하여 마크다운 형태로 출력해라.

# 🚀 카톡방 주식 찌라시 & 개미 심리 리포트 ({datetime.date.today().strftime('%Y-%m-%d')})

## 1. 🔥 오늘 카톡방 핫 종목 TOP 3
- 종목명 (국내/미국 구분): 대화 속 주요 매매/관심 사유 및 이슈 요약

## 2. 🛒 매수 vs 매도 대화 현황
- **매수/추매 정황**: 매수 언급 대화 핵심 내용
- **매도/손절 정황**: 매도 언급 대화 핵심 내용

## 3. 🌡️ 카톡방 개미 투자 심리 온도계
- **심리 온도**: [예: 85℃ - FOMO 폭발 & 뇌동매매 주의 / 20℃ - 공포 절정 손절 타임]
- **심리 요약**: 카톡방 참여자들의 전반적인 투자 분위기 2줄 요약

## 4. 💡 개미 파수꾼의 팩트체크 & 한 줄 총평
- 뇌동매매 방지 팁 및 위트 있는 한 줄 조언
"""

    # Gemini REST API 호출 (standard python library urllib 사용으로 외부 패키지 설치 의존성 제거)
    models_to_try = [
        "gemini-2.5-flash",
        "gemini-2.0-flash",
        "gemini-1.5-flash"
    ]

    for model in models_to_try:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
        headers = {"Content-Type": "application/json"}
        payload = {
            "contents": [{
                "parts": [{"text": prompt}]
            }]
        }
        
        try:
            req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers=headers)
            with urllib.request.urlopen(req) as response:
                res_json = json.loads(response.read().decode("utf-8"))
                text = res_json['candidates'][0]['content']['parts'][0]['text']
                return text
        except urllib.error.HTTPError as e:
            if e.code == 404:
                continue # 다음 모델 시도
            else:
                err_msg = e.read().decode('utf-8')
                print(f"Gemini API 오류 ({model}): {e.code} - {err_msg}")
                break
        except Exception as e:
            print(f"Gemini API 호출 실패 ({model}): {e}")
            break

    # SDK 패키지가 존재하는 경우 fallback
    try:
        import google.generativeai as genai
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-1.5-flash")
        response = model.generate_content(prompt)
        return response.text
    except Exception as ex:
        print(f"Gemini SDK fallback 실패: {ex}")

    return "❌ Gemini API 호출에 실패하였습니다. API 키와 네트워크 연결을 확인하세요."

def refresh_kakao_token(config):
    """카카오 Access Token 갱신"""
    print("🔄 카카오 Access Token 갱신 시도...")
    refresh_url = "https://kauth.kakao.com/oauth/token"
    payload = urllib.parse.urlencode({
        "grant_type": "refresh_token",
        "client_id": config.get("rest_api_key", ""),
        "refresh_token": config.get("refresh_token", "")
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
                save_kakao_config(config)
                print("✅ 카카오 Access Token이 성공적으로 갱신되었습니다.")
                return True
    except Exception as e:
        print(f"❌ 토큰 갱신 실패: {e}")
    return False

def format_kakao_talk_message(markdown_report):
    """카카오톡 메시지용 요약 텍스트 생성 (글자 수 1,000자 이내 제한)"""
    today_str = datetime.date.today().strftime('%Y-%m-%d')
    lines = [
        f"📱 [카톡방 주식 대화 분석 리포트 - {today_str}]",
        "------------------------------------"
    ]

    report_lines = markdown_report.splitlines()
    sec = ""
    for line in report_lines:
        line_str = line.strip()
        if "핫 종목" in line_str:
            sec = "HOT"
            lines.append("\n🔥 [오늘의 핫 종목]")
            continue
        elif "매수 vs 매도" in line_str:
            sec = "TRADE"
            lines.append("\n🛒 [매수/매도 현황]")
            continue
        elif "투자 심리" in line_str:
            sec = "SENTIMENT"
            lines.append("\n🌡️ [개미 심리 온도계]")
            continue
        elif "한 줄 총평" in line_str:
            sec = "ADVICE"
            lines.append("\n💡 [파수꾼의 조언]")
            continue

        if sec and line_str and not line_str.startswith("#"):
            lines.append(line_str)

    final_msg = "\n".join(lines)
    if len(final_msg) > 950:
        final_msg = final_msg[:900] + "\n...(중략)...\n------------------------------------"
    
    return final_msg

def send_kakao_memo(access_token, message_text):
    """카카오톡 '나와의 채팅방'으로 메시지 전송"""
    send_url = "https://kapi.kakao.com/v2/api/talk/memo/default/send"
    template_obj = {
        "object_type": "text",
        "text": message_text,
        "link": {
            "web_url": "https://developers.kakao.com",
            "mobile_web_url": "https://developers.kakao.com"
        },
        "button_title": "📊 리포트 확인"
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
    parser = argparse.ArgumentParser(description="카카오톡 대화 내역 주식 분석 및 카카오톡 전송 스크립트")
    parser.add_argument("--chat-dir", default=DEFAULT_CHAT_DIR, help="카카오톡 .txt 파일 폴더 경로")
    parser.add_argument("--dry-run", action="store_true", help="실제 카카오톡 전송 없이 콘솔 출력만 수행")
    parser.add_argument("--api-key", help="Gemini API Key")
    args = parser.parse_args()

    config = load_kakao_config()
    gemini_key = get_gemini_api_key(config, args.api_key)

    if not gemini_key:
        print("\n❌ 오류: Gemini API Key가 입력되지 않았습니다.")
        print("💡 해결방법: 환경 변수 GEMINI_API_KEY 설정 또는 '--api-key YOUR_KEY' 사용")
        print("    또는 kakao_config.json에 \"gemini_api_key\": \"YOUR_KEY\" 항목을 추가하세요.\n")
        sys.exit(1)

    # 1. 카카오톡 대화 내역 로드
    chat_content = load_chat_files(args.chat_dir)
    if not chat_content:
        print(f"❌ 대화 내용이 비어있거나 '{args.chat_dir}' 폴더에 .txt 파일이 없습니다.")
        sys.exit(1)

    # 2. Gemini API로 주식 대화 분석 리포트 작성
    markdown_report = analyze_chat_with_gemini(chat_content, gemini_key)
    
    # 3. 리포트 파일 저장 (.md)
    today_str = datetime.date.today().strftime('%Y%m%d')
    output_filename = f"kakao_chat_stock_report_{today_str}.md"
    output_path = os.path.join(BASE_DIR, output_filename)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(markdown_report)

    print(f"\n📄 분석 리포트 저장 완료: {output_filename}")

    # 4. 카카오톡 메시지 변환
    formatted_msg = format_kakao_talk_message(markdown_report)

    if args.dry_run:
        print("\n" + "=" * 50)
        print("[🔍 Dry-Run 모드: 카카오톡 발송 생략 및 결과 출력]")
        print("=" * 50)
        print(formatted_msg)
        print("=" * 50)
        return

    # 5. 카카오톡 나와의 채팅방 전송
    access_token = config.get("access_token", "")
    if not access_token:
        if not refresh_kakao_token(config):
            print("❌ 토큰 갱신 실패. kakao_config.json 설정을 확인하세요.")
            sys.exit(1)
        access_token = config.get("access_token", "")

    try:
        res = send_kakao_memo(access_token, formatted_msg)
        if res.get("result_code") == 0:
            print("\n🎉 [성공] 카카오톡 나와의 채팅방으로 주식 대화 분석 리포트가 전송되었습니다!")
        else:
            print(f"❌ 전송 실패 (코드: {res.get('result_code')})")
    except urllib.error.HTTPError as e:
        if e.code == 401:
            print("🔑 Access Token 만료됨. 재갱신 시도 중...")
            if refresh_kakao_token(config):
                access_token = config.get("access_token", "")
                retry_res = send_kakao_memo(access_token, formatted_msg)
                if retry_res.get("result_code") == 0:
                    print("\n🎉 [성공] 토큰 갱신 후 카카오톡 전송 성공!")
                    return
        print(f"❌ 카카오톡 API 오류: {e}")

if __name__ == "__main__":
    main()

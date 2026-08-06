import os
import sys
import json
import urllib.request
import urllib.parse

CONFIG_FILE = os.path.join(os.path.dirname(__file__), "kakao_config.json")

def load_config():
    if not os.path.exists(CONFIG_FILE):
        return {
            "rest_api_key": "YOUR_REST_API_KEY_HERE",
            "redirect_uri": "http://localhost:5000/oauth",
            "access_token": "",
            "refresh_token": ""
        }
    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def save_config(config):
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(config, f, ensure_ascii=False, indent=2)

def main():
    config = load_config()
    api_key = config.get("rest_api_key", "").strip()
    
    if not api_key or api_key == "YOUR_REST_API_KEY_HERE":
        api_key = input("카카오 디벨로퍼스 REST API 키를 입력하세요: ").strip()
        if not api_key:
            print("Error: REST API 키가 입력되지 않았습니다.")
            sys.exit(1)
        config["rest_api_key"] = api_key
        save_config(config)

    redirect_uri = config.get("redirect_uri", "http://localhost:5000/oauth")
    auth_url = f"https://kauth.kakao.com/oauth/authorize?client_id={api_key}&redirect_uri={urllib.parse.quote(redirect_uri)}&response_type=code&scope=talk_message"

    print("\n" + "=" * 70)
    print("[1단계] 아래 URL을 웹 브라우저 주소창에 복사/붙여넣기하여 접속하세요:")
    print(auth_url)
    print("=" * 70)
    print("로그인 및 동의 후 이동되는 브라우저 주소창의 ?code= 뒷부분 값(인가 코드)을 복사하세요.\n")

    auth_code = input("복사한 인가 코드(code)를 입력하세요: ").strip()
    if not auth_code:
        print("Error: 인가 코드가 입력되지 않았습니다.")
        sys.exit(1)

    print("\n[2단계] 카카오 서버에 토큰 발급 요청 중...")
    token_url = "https://kauth.kakao.com/oauth/token"
    payload = urllib.parse.urlencode({
        "grant_type": "authorization_code",
        "client_id": api_key,
        "redirect_uri": redirect_uri,
        "code": auth_code
    }).encode("utf-8")

    req = urllib.request.Request(token_url, data=payload, headers={
        "Content-Type": "application/x-www-form-urlencoded;charset=utf-8"
    })

    try:
        with urllib.request.urlopen(req) as res:
            res_data = json.loads(res.read().decode("utf-8"))
            config["access_token"] = res_data.get("access_token", "")
            config["refresh_token"] = res_data.get("refresh_token", "")
            save_config(config)

            print("\n" + "=" * 70)
            print("🎉 [성공] 카카오톡 API 토큰이 성공적으로 발급 및 저장되었습니다!")
            print(f"Access Token : {config['access_token'][:12]}...")
            print(f"Refresh Token: {config['refresh_token'][:12]}...")
            print("=" * 70)
            print("이제 send_kakao_report.py를 실행하여 카카오톡으로 발송 가능합니다.")
    except Exception as e:
        print(f"\n❌ [오류 발생] 토큰 발급 실패: {e}")

if __name__ == "__main__":
    main()

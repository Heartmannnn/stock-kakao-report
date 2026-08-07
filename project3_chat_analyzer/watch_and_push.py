# ==============================================================================
# Project 3: Reliable Python File Watcher Daemon (watch_and_push.py)
# Zero CPU usage (time.sleep(2)), robust cross-platform file change detector
# ==============================================================================

import os
import sys
import time
import subprocess
import datetime

def get_latest_chat_file(watch_dir):
    if not os.path.exists(watch_dir):
        return None, 0
    txt_files = [
        os.path.join(watch_dir, f) for f in os.listdir(watch_dir)
        if f.endswith('.txt') and not f.startswith('.')
    ]
    if not txt_files:
        return None, 0
    
    txt_files.sort(key=lambda x: os.path.getmtime(x), reverse=True)
    latest_file = txt_files[0]
    return latest_file, os.path.getmtime(latest_file)

def log(msg):
    t_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{t_str}] {msg}"
    print(line, flush=True)
    base_dir = os.path.dirname(os.path.abspath(__file__))
    log_file = os.path.join(base_dir, "watcher.log")
    try:
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception:
        pass

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    watch_dir = os.path.join(base_dir, "chat_logs")
    repo_root = os.path.dirname(base_dir)

    log(f"🚀 Starting Project 3 Python File Watcher on: {watch_dir}")
    
    last_file, last_mtime = get_latest_chat_file(watch_dir)
    log(f"Initial latest file: {os.path.basename(last_file) if last_file else 'None'} (mtime: {last_mtime})")

    git_exe = r"C:\Program Files\Git\cmd\git.exe"

    while True:
        try:
            time.sleep(2)
            curr_file, curr_mtime = get_latest_chat_file(watch_dir)
            
            if curr_file and curr_mtime > last_mtime:
                fname = os.path.basename(curr_file)
                log(f"🔔 NEW CHAT FILE DETECTED: {fname} (mtime changed)")
                
                # Wait 2 seconds to ensure file copy is completed by OS
                time.sleep(2)
                
                log(f"⬆️ Committing and pushing {fname} to GitHub Cloud...")
                
                try:
                    subprocess.run([git_exe, "-C", repo_root, "add", "."], check=True, capture_output=True)
                    subprocess.run([git_exe, "-C", repo_root, "commit", "-m", f"Auto-push chat log {fname} by Python File Watcher"], check=True, capture_output=True)
                    subprocess.run([git_exe, "-C", repo_root, "push", "origin", "main", "--force"], check=True, capture_output=True)
                    log(f"🎉 [SUCCESS] {fname} pushed to GitHub! Cloud Action triggered.")
                except subprocess.CalledProcessError as pe:
                    log(f"Git command note: {pe.stderr.decode('utf-8', errors='ignore')}")

                last_file = curr_file
                last_mtime = curr_mtime

        except KeyboardInterrupt:
            log("🛑 Python Watcher stopped by user.")
            break
        except Exception as e:
            log(f"Watcher loop exception: {e}")

if __name__ == "__main__":
    main()

import subprocess
import webbrowser
import os
import sys

def main():
    project_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(project_dir)
    
    print("=" * 70)
    print("📡 TRẠM ĐỘC LẬP GIẢ LẬP IOT REALTIME 30S")
    print("🌐 Đang khởi chạy web app độc lập tại: http://localhost:5175")
    print("=" * 70)
    
    webbrowser.open("http://localhost:5175")
    
    try:
        subprocess.run(["npx", "vite", "--port", "5175", "--host"], check=True, shell=True)
    except KeyboardInterrupt:
        print("\nĐã dừng máy chủ giả lập IoT.")

if __name__ == "__main__":
    main()

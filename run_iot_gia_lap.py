import http.server
import socketserver
import webbrowser
import os

PORT = 5175
HTML_FILE = "iot_gia_lap.html"

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/" or self.path == "":
            self.path = f"/{HTML_FILE}"
        return super().do_GET()

def run_server():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    url = f"http://localhost:{PORT}/"
    print("=" * 70)
    print(f"📡 TRẠM ĐỘC LẬP GIẢ LẬP IOT & TELEMETRY 30S")
    print(f"🌐 Đang mở giao diện tại: {url}")
    print("=" * 70)
    
    webbrowser.open(url)
    
    with socketserver.TCPServer(("", PORT), CustomHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nĐã dừng máy chủ giả lập IoT.")

if __name__ == "__main__":
    run_server()

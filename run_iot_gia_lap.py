import http.server
import socketserver
import webbrowser
import os
import sys

PORT = 5175
HTML_FILE = "iot_gia_lap.html"

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/" or self.path == "":
            self.path = f"/{HTML_FILE}"
        return super().do_GET()

def run_server():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    url = f"http://localhost:{PORT}/"
    print("=" * 70)
    print(f"[*] TRAM DOC LAP GIA LAP IOT & TELEMETRY 30S")
    print(f"[*] Dang mo giao dien tai: {url}")
    print("=" * 70)
    
    webbrowser.open(url)
    
    with socketserver.TCPServer(("", PORT), CustomHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nDa dung may chu gia lap IoT.")

if __name__ == "__main__":
    run_server()


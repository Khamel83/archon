#!/usr/bin/env python3
"""
Simple HTTP server to serve the Universal Caddy Solution files
Access via: http://your-server-ip:8888/
"""

import http.server
import socketserver
import os
from pathlib import Path

PORT = 8888
SOLUTION_DIR = "/home/ubuntu/universal-caddy-solution"

class SolutionHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=SOLUTION_DIR, **kwargs)

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

if __name__ == "__main__":
    os.chdir(SOLUTION_DIR)

    with socketserver.TCPServer(("", PORT), SolutionHandler) as httpd:
        print(f"🌐 Serving Universal Caddy Solution at http://localhost:{PORT}/")
        print(f"📁 Serving files from: {SOLUTION_DIR}")
        print("")
        print("📋 Available files:")
        for file in Path(SOLUTION_DIR).rglob("*"):
            if file.is_file():
                print(f"   http://localhost:{PORT}/{file.relative_to(SOLUTION_DIR)}")
        print("")
        print("🔗 Quick install command for other servers:")
        print(f"   curl -sSL http://YOUR-SERVER-IP:{PORT}/install.sh | bash")

        httpd.serve_forever()
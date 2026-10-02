#!/usr/bin/env python3
# Copyright 2026 Schwarz Digits Cloud GmbH & Co. KG
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# HTTP backend for web application firewall tests. It answers every request
# with 200 and reports the backend, the method, the path and the size of the
# request body, so a response proves that the firewall let the request pass.
# Usage: server.py [port]
import json
import socket
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
HOSTNAME = socket.gethostname()


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        # Silence the per-request log of BaseHTTPRequestHandler; the health
        # checks of the load balancer alone would add a line every few seconds.
        pass

    def reply(self):
        length = int(self.headers.get("Content-Length") or 0)
        if length:
            self.rfile.read(length)
        body = {
            "backend": HOSTNAME,
            "method": self.command,
            "path": self.path,
            "body_bytes": length,
        }
        payload = (json.dumps(body) + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(payload)

    do_GET = do_HEAD = do_POST = do_PUT = do_PATCH = do_DELETE = reply


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()

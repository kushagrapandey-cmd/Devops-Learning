"""Internal-only HTTP probe API, using Python's standard library."""
import json
import logging
import os
import signal
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit
from sentinel.health import snapshot

LOG = logging.getLogger("sentinel")


def make_handler(not_ready):
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            path = urlsplit(self.path).path
            if path == "/healthz":
                code, body = 200, {"status": "alive"}
            elif path == "/readyz":
                ready = not not_ready.exists()
                code, body = (200 if ready else 503), {"ready": ready}
            elif path == "/api/status":
                try:
                    code, body = 200, snapshot()
                except (OSError, ValueError, KeyError) as exc:
                    LOG.error(json.dumps({"event": "collection_failed", "error": str(exc)}))
                    code, body = 503, {"status": "unavailable"}
            else:
                code, body = 404, {"error": "not_found"}
            data = json.dumps(body).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)
            LOG.info(json.dumps({"event": "request", "path": path, "status": code}))

        def log_message(self, *args):
            pass
    return Handler


def main():
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    server = ThreadingHTTPServer((os.getenv("BIND", "127.0.0.1"),
                                 int(os.getenv("PORT", "8080"))),
                                make_handler(Path(os.getenv("NOT_READY_FILE", "/tmp/sentinel-not-ready"))))
    server.daemon_threads = True
    # shutdown() must run on a different thread from serve_forever().
    def stop(*_):
        threading.Thread(target=server.shutdown, daemon=True).start()
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    LOG.info(json.dumps({"event": "started", "port": server.server_port}))
    try:
        server.serve_forever(poll_interval=0.2)
    finally:
        server.server_close()
        LOG.info(json.dumps({"event": "stopped"}))


if __name__ == "__main__":
    main()

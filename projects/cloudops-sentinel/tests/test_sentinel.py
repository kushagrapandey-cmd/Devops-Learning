import io
import json
import os
import signal
import socket
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from http.server import ThreadingHTTPServer
from pathlib import Path
from unittest.mock import patch
from urllib.error import HTTPError
from urllib.request import urlopen

from sentinel.cli import summarize
from sentinel.health import memory_percent, snapshot
from sentinel.server import make_handler


class HealthTests(unittest.TestCase):
    def test_memory_uses_available_not_free(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'meminfo'
            path.write_text('MemTotal: 1000 kB\nMemFree: 100 kB\nMemAvailable: 400 kB\n')
            self.assertEqual(memory_percent(path), 60)

    def test_invalid_total(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'meminfo'
            path.write_text('MemTotal: 0 kB\nMemAvailable: 0 kB\n')
            with self.assertRaises(ValueError):
                memory_percent(path)

    @patch('sentinel.health.memory_percent', return_value=90)
    @patch('sentinel.health.shutil.disk_usage', return_value=type('Disk', (), {'used': 85, 'total': 100})())
    def test_alerts_include_exact_boundary(self, *_):
        result = snapshot()
        self.assertEqual(result['status'], 'warning')
        self.assertEqual(len(result['alerts']), 2)

    def test_missing_disk_returns_collection_error(self):
        result = subprocess.run([sys.executable, '-m', 'sentinel.cli', 'check', '--disk-path', '/missing-sentinel-path'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn('error', json.loads(result.stdout))

    def test_invalid_percentage_rejected(self):
        result = subprocess.run([sys.executable, '-m', 'sentinel.cli', 'check', '--disk-threshold', '101'], capture_output=True)
        self.assertEqual(result.returncode, 2)


class LogTests(unittest.TestCase):
    def test_errors_and_malformed_lines(self):
        data = summarize(io.StringIO('{"status":200}\n{"status":503}\nnope\n[]\n{"status":true}\n'))
        self.assertEqual(data['requests'], 2)
        self.assertEqual(data['error_percent'], 50)
        self.assertEqual(data['malformed_or_non_request_lines'], 3)

    def test_empty_logs_do_not_divide_by_zero(self):
        self.assertEqual(summarize([])['error_percent'], 0)

    def test_client_errors_are_not_server_errors(self):
        self.assertEqual(summarize(['{"status":404}'])['server_errors'], 0)

    def test_log_cli_no_requests_is_not_healthy(self):
        with tempfile.NamedTemporaryFile(mode='w') as source:
            source.write('invalid\n'); source.flush()
            result = subprocess.run([sys.executable, '-m', 'sentinel.cli', 'logs', source.name], capture_output=True)
            self.assertEqual(result.returncode, 2)

    def test_log_cli_alert(self):
        with tempfile.NamedTemporaryFile(mode='w') as source:
            source.write('{"status":503}\n'); source.flush()
            result = subprocess.run([sys.executable, '-m', 'sentinel.cli', 'logs', source.name], capture_output=True)
            self.assertEqual(result.returncode, 1)


class HTTPTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.marker = Path(self.directory.name) / 'not-ready'
        self.server = ThreadingHTTPServer(('127.0.0.1', 0), make_handler(self.marker))
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.base = f'http://127.0.0.1:{self.server.server_port}'

    def tearDown(self):
        self.server.shutdown(); self.server.server_close(); self.thread.join()
        self.directory.cleanup()

    def get(self, path):
        try:
            with urlopen(self.base + path, timeout=3) as response:
                return response.status, json.load(response)
        except HTTPError as error:
            return error.code, json.load(error)

    def test_alive(self):
        self.assertEqual(self.get('/healthz'), (200, {'status': 'alive'}))

    def test_readiness_failure_and_recovery_preserves_liveness(self):
        self.assertEqual(self.get('/readyz')[0], 200)
        self.marker.touch()
        self.assertEqual(self.get('/readyz')[0], 503)
        self.assertEqual(self.get('/healthz')[0], 200)
        self.marker.unlink()
        self.assertEqual(self.get('/readyz')[0], 200)

    def test_real_linux_collection(self):
        code, data = self.get('/api/status')
        self.assertEqual(code, 200)
        self.assertTrue(0 <= data['disk_percent'] <= 100)
        self.assertIn('not cgroup', data['scope'])

    @patch('sentinel.server.snapshot', side_effect=OSError('test failure'))
    def test_collection_failure_is_503(self, _):
        self.assertEqual(self.get('/api/status')[0], 503)

    def test_unknown_route(self):
        self.assertEqual(self.get('/does-not-exist')[0], 404)

    def test_concurrent_requests(self):
        from concurrent.futures import ThreadPoolExecutor
        with ThreadPoolExecutor(max_workers=4) as pool:
            statuses = list(pool.map(lambda _: self.get('/healthz')[0], range(12)))
        self.assertEqual(statuses, [200] * 12)


class ProcessTests(unittest.TestCase):
    def test_sigterm_exits_cleanly(self):
        # A dedicated subprocess tests actual signal handling, not a mocked handler.
        with socket.socket() as reservation:
            reservation.bind(('127.0.0.1', 0))
            port = reservation.getsockname()[1]
        env = dict(os.environ, BIND='127.0.0.1', PORT=str(port))
        process = subprocess.Popen([sys.executable, '-m', 'sentinel.server'], env=env,
                                   stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
        try:
            for _ in range(50):
                try:
                    with urlopen(f'http://127.0.0.1:{port}/healthz', timeout=.2):
                        break
                except OSError:
                    time.sleep(.05)
            else:
                self.fail('server did not start')
            process.send_signal(signal.SIGTERM)
            _, logs = process.communicate(timeout=5)
            self.assertEqual(process.returncode, 0)
            self.assertIn('stopped', logs)
        finally:
            if process.poll() is None:
                process.kill(); process.communicate()


if __name__ == '__main__':
    unittest.main()

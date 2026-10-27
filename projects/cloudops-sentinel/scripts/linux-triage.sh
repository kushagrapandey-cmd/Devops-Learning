#!/usr/bin/env bash
# Local read-only diagnostics. Reports may contain host/network identifiers; do not commit them.
set -euo pipefail
umask 077
cd "$(dirname "${BASH_SOURCE[0]}")/.."
mkdir -p reports
report=$(mktemp reports/linux-triage.XXXXXX.txt)
for tool in uptime free df ps ss; do
  if ! command -v "$tool" >/dev/null; then echo "Missing required command: $tool" >&2; exit 2; fi
done
{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  echo '--- load and uptime ---'
  uptime
  echo '--- memory (MiB) ---'
  free -m
  echo '--- filesystem usage ---'
  df -h /
  echo '--- top CPU processes ---'
  # sed reads the entire stream; unlike head it does not cause SIGPIPE under pipefail.
  ps -eo pid,comm,%cpu,%mem --sort=-%cpu | sed -n '1,11p'
  echo '--- listening TCP sockets ---'
  ss -ltn
} > "$report"
echo "$report"

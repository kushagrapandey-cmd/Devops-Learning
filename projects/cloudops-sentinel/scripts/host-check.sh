#!/usr/bin/env bash
# stdout is a JSON report. Exit 0=healthy, 1=threshold crossed, 2=collection error.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
command -v python3 >/dev/null || { echo 'python3 is required' >&2; exit 2; }
exec python3 -m sentinel.cli check "$@"

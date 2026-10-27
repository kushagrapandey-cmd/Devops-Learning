#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
python3 -m unittest discover -s tests -v
for script in scripts/*.sh azure/*.sh; do bash -n "$script"; done
python3 -m compileall -q sentinel

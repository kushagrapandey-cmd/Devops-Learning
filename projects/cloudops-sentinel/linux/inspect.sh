#!/usr/bin/env bash
# Read-only checks: nonzero status is evidence, so each layer is printed independently.
set -uo pipefail
for command in 'systemctl status sentinel --no-pager' 'journalctl -u sentinel -n 25 --no-pager' 'ss -ltn' 'df -h /' 'free -m'; do
  echo "Checking: $command"
  # Fixed commands supplied by this script, never user input.
  read -r -a arguments <<< "$command"
  "${arguments[@]}" || echo "Check returned nonzero: $command"
done
curl --max-time 5 -fsS http://127.0.0.1:8080/healthz || echo 'Local HTTP check failed'

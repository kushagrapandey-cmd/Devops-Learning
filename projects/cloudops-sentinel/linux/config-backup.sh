#!/usr/bin/env bash
# This backup covers only app.env, not packages, VM disks or application data.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run with sudo' >&2; exit 2; }
umask 077
case "${1:-}" in
  backup)
    install -d -m 700 /var/backups/sentinel-lab
    target=$(mktemp /var/backups/sentinel-lab/app.env.XXXXXX)
    cp /etc/sentinel-lab/app.env "$target"
    sha256sum "$target"
    ;;
  restore)
    source_file="${2:?Pass an absolute backup path}"
    [[ "${3:-}" == --restore-lab-config ]] || { echo 'Use --restore-lab-config' >&2; exit 2; }
    [[ "$source_file" == /var/backups/sentinel-lab/app.env.* && -f "$source_file" && ! -L "$source_file" ]] || exit 2
    python3 - "$source_file" <<'CHECK'
from pathlib import Path
import sys
lines=Path(sys.argv[1]).read_text().splitlines()
assert len(lines)==2 and lines[0]=='BIND=127.0.0.1' and lines[1]=='PORT=8080', 'Only baseline lab config can be restored'
CHECK
    install -m 644 "$source_file" /etc/sentinel-lab/app.env
    systemctl restart sentinel
    curl --retry 10 --retry-connrefused --retry-delay 1 -fsS http://127.0.0.1:8080/healthz
    ;;
  *) echo 'Usage: config-backup.sh backup | restore PATH --restore-lab-config' >&2; exit 2 ;;
esac

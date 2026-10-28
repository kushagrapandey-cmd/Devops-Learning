#!/usr/bin/env bash
# Ubuntu-only maintenance helper: default is a simulation, never an automatic reboot.
set -euo pipefail
mode="${1:-plan}"
[[ -d /etc/sentinel-lab ]] || { echo 'Dedicated lab installation required' >&2; exit 2; }
case "$mode" in
  plan) apt-get --simulate upgrade ;;
  apply)
    [[ "${2:-}" == --maintenance-approved ]] || { echo 'Use apply --maintenance-approved after prechecks and backup.' >&2; exit 2; }
    [[ $EUID -eq 0 ]] || { echo 'Run with sudo' >&2; exit 2; }
    curl --max-time 5 -fsS http://127.0.0.1:8080/healthz
    apt-get update
    # Interactive confirmation remains: review packages before accepting.
    apt-get upgrade
    systemctl is-active sentinel
    curl --max-time 5 -fsS http://127.0.0.1:8080/healthz
    if [[ -f /var/run/reboot-required ]]; then echo 'REBOOT REQUIRED: schedule it explicitly; this script does not reboot.'; fi
    ;;
  *) echo 'Usage: patch.sh [plan|apply --maintenance-approved]' >&2; exit 2 ;;
esac

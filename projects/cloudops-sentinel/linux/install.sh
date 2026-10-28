#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == --install-dedicated-lab ]] || { echo 'Use --install-dedicated-lab on a dedicated Ubuntu VM only.' >&2; exit 2; }
[[ $EUID -eq 0 ]] || { echo 'Run with sudo' >&2; exit 2; }
cd "$(dirname "${BASH_SOURCE[0]}")/.."
command -v python3 >/dev/null
systemctl --version >/dev/null
if ! id sentinel >/dev/null 2>&1; then useradd --system --no-create-home --shell /usr/sbin/nologin sentinel; fi
install -d -m 755 /opt/sentinel /etc/sentinel-lab
cp -R sentinel /opt/sentinel/
chown -R root:root /opt/sentinel
# Never overwrite a learner's configuration on a second install.
if [[ ! -f /etc/sentinel-lab/app.env ]]; then
  printf 'BIND=127.0.0.1\nPORT=8080\n' > /etc/sentinel-lab/app.env
fi
chmod 644 /etc/sentinel-lab/app.env
install -m 644 linux/sentinel.service /etc/systemd/system/sentinel.service
systemctl daemon-reload
systemctl enable --now sentinel
curl --retry 10 --retry-connrefused --retry-delay 1 -fsS http://127.0.0.1:8080/healthz

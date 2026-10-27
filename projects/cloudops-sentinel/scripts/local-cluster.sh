#!/usr/bin/env bash
# Requires a running Docker engine, kind and kubectl. Creates only a local cluster.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
for tool in docker kind kubectl; do command -v "$tool" >/dev/null; done
if ! kind get clusters | grep -qx sentinel; then kind create cluster --name sentinel --wait 120s; fi
docker build -t sentinel:local .
kind load docker-image sentinel:local --name sentinel
EXPECTED_CONTEXT=kind-sentinel IMAGE=sentinel:local bash scripts/deploy.sh
echo 'Run: kubectl --context kind-sentinel -n sentinel port-forward svc/sentinel 8080:80'

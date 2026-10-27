#!/usr/bin/env bash
# Deliberately disruptive: local dedicated cluster only, never an AKS context.
set -euo pipefail
[[ "$(kubectl config current-context)" == kind-sentinel ]] || { echo 'Use kind-sentinel only' >&2; exit 2; }
ns=sentinel
kubectl -n "$ns" rollout status deployment/sentinel --timeout=120s
pod=$(kubectl -n "$ns" get pods -l app=sentinel -o jsonpath='{.items[0].metadata.name}')
cleanup() {
  kubectl -n "$ns" exec "$pod" -- python -c 'from pathlib import Path; Path("/tmp/sentinel-not-ready").unlink(missing_ok=True)' 2>/dev/null || true
}
trap cleanup EXIT
echo '1. Readiness failure: process stays alive, one pod leaves Service endpoints.'
kubectl -n "$ns" exec "$pod" -- python -c 'from pathlib import Path; Path("/tmp/sentinel-not-ready").touch()'
kubectl -n "$ns" wait --for=condition=Ready=false "pod/$pod" --timeout=60s
cleanup
kubectl -n "$ns" wait --for=condition=Ready "pod/$pod" --timeout=60s
echo '2. Delete a pod: Deployment controller replaces it.'
kubectl -n "$ns" delete pod "$pod" --wait=true
kubectl -n "$ns" rollout status deployment/sentinel --timeout=120s
kubectl -n "$ns" wait --for=condition=Ready pod -l app=sentinel --timeout=120s
echo '3. Bad release: missing image fails rollout. Operator explicitly rolls back.'
kubectl -n "$ns" set image deployment/sentinel sentinel=sentinel:deliberately-missing
if kubectl -n "$ns" rollout status deployment/sentinel --timeout=30s; then
  echo 'Unexpected successful rollout' >&2; exit 1
fi
kubectl -n "$ns" rollout undo deployment/sentinel
kubectl -n "$ns" rollout status deployment/sentinel --timeout=120s
kubectl -n "$ns" wait --for=condition=Ready pod -l app=sentinel --timeout=120s

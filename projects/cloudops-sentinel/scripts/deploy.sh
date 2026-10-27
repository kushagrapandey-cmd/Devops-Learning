#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
: "${EXPECTED_CONTEXT:?Set EXPECTED_CONTEXT after inspecting kubectl config current-context}"
: "${IMAGE:?Set IMAGE to an immutable tag or digest accessible by the cluster}"
[[ "$(kubectl config current-context)" == "$EXPECTED_CONTEXT" ]] || { echo 'Context mismatch' >&2; exit 2; }
# Render the Deployment first: never apply the placeholder image to a live cluster.
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT
kubectl set image -f k8s/deployment.yaml sentinel="$IMAGE" --local -o yaml > "$temporary/deployment.yaml"
kubectl apply -f k8s/namespace.yaml -f k8s/service.yaml -f "$temporary/deployment.yaml"
kubectl -n sentinel rollout status deployment/sentinel --timeout=180s

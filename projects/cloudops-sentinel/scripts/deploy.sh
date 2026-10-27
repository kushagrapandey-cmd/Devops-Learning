#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
: "${EXPECTED_CONTEXT:?Set EXPECTED_CONTEXT after inspecting kubectl config current-context}"
: "${IMAGE:?Set IMAGE to an immutable tag or digest accessible by the cluster}"
[[ "$(kubectl config current-context)" == "$EXPECTED_CONTEXT" ]] || { echo 'Context mismatch' >&2; exit 2; }
# Render the Deployment first: never apply the placeholder image to a live cluster.
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT
python3 - "$IMAGE" "$temporary/deployment.yaml" <<'PY'
import json, sys
from pathlib import Path
source = Path("k8s/deployment.yaml").read_text()
Path(sys.argv[2]).write_text(source.replace("image: sentinel:local", "image: " + json.dumps(sys.argv[1])))
PY
kubectl apply -f k8s/namespace.yaml -f k8s/service.yaml -f "$temporary/deployment.yaml"
kubectl -n sentinel rollout status deployment/sentinel --timeout=180s

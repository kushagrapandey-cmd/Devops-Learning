#!/usr/bin/env bash
# Read-only triage; use a namespace argument to avoid scanning other workloads.
set -euo pipefail
namespace="${1:-sentinel}"
echo "Context: $(kubectl config current-context)"
kubectl -n "$namespace" get deployment,pods,svc,endpointslices -o wide
kubectl -n "$namespace" get events --sort-by=.lastTimestamp
kubectl -n "$namespace" describe pods -l app=sentinel
kubectl -n "$namespace" logs -l app=sentinel --tail=50 --prefix=true

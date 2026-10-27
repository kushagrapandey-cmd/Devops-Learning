# Reproducible demo

Run all commands from `projects/cloudops-sentinel` on Linux/WSL. This file describes expected outcomes, not prerecorded proof.

## Python-only: no cloud bill

```bash
bash scripts/verify.sh
bash scripts/linux-triage.sh
bash scripts/host-check.sh
# Force an alert without filling a disk. Exit 1 is expected.
bash scripts/host-check.sh --disk-threshold 0
mkdir -p reports
python3 -m sentinel.server 2>reports/app.jsonl
```

In another terminal:

```bash
curl -i http://127.0.0.1:8080/healthz
curl -i http://127.0.0.1:8080/readyz
curl -fsS http://127.0.0.1:8080/api/status
# Affect only this demo process; do not use a shared marker path with other demos.
touch /tmp/sentinel-not-ready
curl -i http://127.0.0.1:8080/readyz  # 503
curl -i http://127.0.0.1:8080/healthz # still 200
rm /tmp/sentinel-not-ready
curl -i http://127.0.0.1:8080/readyz  # 200
python3 -m sentinel.cli logs reports/app.jsonl
```

Stop server with Ctrl+C. The log-summary exit code may be 1 because you deliberately generated a 503; its denominator counts valid HTTP request records, not startup/shutdown log records. These checks verify the app, not Kubernetes traffic handling.

## Container and Kubernetes demo

```bash
bash scripts/local-cluster.sh
kubectl -n sentinel get pods -o wide
kubectl -n sentinel port-forward svc/sentinel 8080:80
```

Curl the endpoints in another terminal. Stop port-forward before the drills because it is attached to a particular pod, which may be deleted.

```bash
bash scripts/drills.sh
bash scripts/diagnose.sh sentinel
kubectl -n sentinel logs -l app=sentinel --tail=500 > reports/kubernetes.jsonl
python3 -m sentinel.cli logs reports/kubernetes.jsonl
kind delete cluster --name sentinel
```

Expected drill observations:

1. Marker makes one pod NotReady; it remains running. Removing the marker restores Ready.
2. Deleting a pod creates a replacement with a new UID/name.
3. Missing image prevents the new pod from starting; rollout wait fails; explicit undo restores the previous ReplicaSet.

For richer evidence, capture `kubectl get pods -w` and `kubectl get endpointslices -l kubernetes.io/service-name=sentinel -o yaml` during a manual marker drill. The script asserts readiness state, but does not measure traffic loss or endpoint propagation latency.

## Suggested five-minute presentation

- Explain the operational problem and scope (30 seconds).
- Run host-check and show a forced threshold warning (45 seconds).
- Explain healthz versus readyz and demonstrate a 503 (60 seconds).
- Show Deployment, Service, security settings and replica recovery (90 seconds).
- Explain the failed image release and explicit rollback (45 seconds).
- Show test evidence and state the Azure deployment status honestly (30 seconds).

Never present expected output as output you captured. Do not publish kubeconfig, subscription identifiers, host reports or Azure tokens.

# CloudOps Sentinel: complete walkthrough

## 1. The problem and the boundary

Imagine an application starts returning errors during your shift. You need answers to different questions: Is the Linux system short on resources? Is the application process alive? Can it accept traffic? Is the new deployment actually working? How many requests failed? This project gives each question a specific tool and output.

It does not connect to SolarWinds or BHOM. The operational pattern is similar: collect evidence, classify the symptom, investigate the cause, recover deliberately, verify recovery.

## 2. File map

| File | Responsibility |
|---|---|
| `sentinel/health.py` | Pure metric collection and threshold decisions |
| `sentinel/cli.py` | CLI parsing, JSON output, exit codes and streaming log analysis |
| `sentinel/server.py` | HTTP routing, structured logs and clean shutdown |
| `sentinel/__init__.py` | Marks the directory as a Python package |
| `scripts/host-check.sh` | Reliable shell entry point to Python checks |
| `scripts/linux-triage.sh` | Linux command report with restricted permissions |
| `scripts/local-cluster.sh` | Build image, create kind cluster, load image and deploy |
| `scripts/deploy.sh` | Context check, manifest rendering, apply and rollout wait |
| `scripts/diagnose.sh` | Read-only Kubernetes troubleshooting commands |
| `scripts/drills.sh` | Three deliberately disruptive local recovery exercises |
| `scripts/verify.sh` | Python tests, Bash parsing and Python compilation |
| `Dockerfile` | Reproducible application packaging recipe |
| `k8s/namespace.yaml` | Isolated namespace and restricted Pod Security enforcement |
| `k8s/deployment.yaml` | Desired replicas, probes, security, resources and update strategy |
| `k8s/service.yaml` | Stable internal service address |
| `k8s/kustomization.yaml` | Groups the three Kubernetes resources |
| `azure/provision.sh` | Explicitly opted-in Azure resource creation |
| `azure/cleanup.sh` | Subscription, name and tag guarded lab deletion |
| `tests/test_sentinel.py` | Threshold, parser, HTTP, concurrency and process tests |
| `.github/workflows/cloudops-sentinel.yml` | Repository-root CI workflow; not inside the project directory |
| `.gitignore` / `.dockerignore` | Keep generated/private files out of git and build context |
| `docs/` and `evidence/` | Instructions, explanation and verification limits |

## 3. Linux: what is actually being measured?

`/proc` is a kernel-provided virtual filesystem. `/proc/meminfo` exposes memory statistics as text. Python splits each line at `:`, reads the numeric value, and calculates:

`memory_percent = (1 - MemAvailable / MemTotal) * 100`

`MemAvailable` estimates memory usable without swapping; `MemFree` alone ignores reclaimable cache. These are host-visible values, not cgroup memory consumption. A pod may hit its 128Mi cgroup limit while the machine still has spare RAM.

`shutil.disk_usage(path)` returns total, used and free bytes for the filesystem containing the path. We calculate `used / total * 100`; this is a simple used-space percentage and can differ from `df` percentages when reserved blocks are involved. It is not inode usage.

`os.getloadavg()[0]` is one-minute load average. It reflects runnable tasks and certain waiting tasks. It is not the same as CPU usage and depends on available CPUs. We report it without inventing a universal alarm threshold.

`linux-triage.sh` runs `uptime`, `free -m`, `df -h /`, `ps` and `ss -ltn`. They reveal uptime/load, memory, storage, processes and listening TCP ports. `ps` output is a snapshot; `%CPU` there is not a perfect short-interval profiler. No command deletes files or restarts services. Reports can contain machine-specific information, so `umask 077` and ignored `reports/` keep them private by default.

## 4. Bash: why these lines matter

- `#!/usr/bin/env bash` selects Bash through PATH.
- `set -euo pipefail`: fail on unhandled command errors, unset variables and failing pipeline components. It does not replace explicit logic for expected failures.
- `"$variable"`: preserves spaces and avoids accidental wildcard expansion.
- `$(...)`: captures a command's output.
- `${BASH_SOURCE[0]}`: finds the script rather than trusting the caller's directory.
- `: "${IMAGE:?message}"`: rejects a missing or empty required setting before a mutation.
- `exec python3 ...`: replaces the shell with Python and preserves its exit status.
- `trap ... EXIT`: removes temporary files even if deployment fails.
- `if command; then ...; fi`: handles a failure we expect, such as the deliberately broken release.

A cron job can redirect JSON into a report, but this project does not install cron jobs or send notifications. Exit codes are a contract that a scheduler or monitoring tool can consume.

## 5. Python: separation of responsibilities

`health.snapshot()` reads metrics and returns a dictionary. It does not print or exit. That makes it reusable from both the CLI and the server. The CLI converts a dictionary to JSON for machines and humans. `argparse` validates percentage values in the inclusive range 0–100.

Host-check exits `0` for no alerts, `1` when at least one threshold is crossed, `2` when collection/input fails. Comparisons use `>=`: exactly 85% disk reaches the default 85 threshold. Tests cover that boundary.

The log analyzer reads one JSON record at a time; it does not load the whole log into memory. `Counter` groups HTTP statuses. It counts 5xx as server errors, not 4xx. Error rate = server-error requests / valid request records. Startup/shutdown records and malformed JSON increment a separate counter; an empty file returns exit `2` because there is insufficient request evidence.

Only our JSON log format is supported. An NGINX text log needs a separate parser. The analyzer never evaluates log strings as Python or shell commands.

## 6. HTTP: a request's entire path

Without containers: curl connects to `127.0.0.1:8080`; `ThreadingHTTPServer` accepts the connection and dispatches a GET to the handler. The handler selects a route, serializes a dictionary to JSON, writes HTTP headers/body and logs the status.

| Endpoint | Meaning | Failure behavior |
|---|---|---|
| `/healthz` | Request handler is responding | Nonresponsive process makes the probe fail |
| `/readyz` | This instance is permitted to receive traffic | Marker file exists → 503 |
| `/api/status` | Diagnostic Linux snapshot | Collection failure → 503; high usage → 200 with warning |
| Unknown GET | Route missing | 404 JSON |

`NOT_READY_FILE` is a local, reversible drill control; no remote endpoint can toggle it. The marker defaults to `/tmp/sentinel-not-ready`. Creating it changes readiness without killing the process. Removing it restores readiness.

The server defaults to loopback for local safety. In a container it binds `0.0.0.0`, so the kubelet can connect through the pod IP. JSON logs go to stderr through Python logging; collect local logs with `2>reports/app.jsonl`.

Kubernetes sends SIGTERM before force killing a terminating container. The signal handler calls shutdown in a separate thread to avoid deadlocking the server loop; `server_close()` releases the socket. An integration test launches a real subprocess and verifies exit code zero after SIGTERM.

This is a deliberately small internal server: no TLS/auth, request rate limiting or production-grade slow-client protection. Do not expose it on the public internet.

## 7. Docker: package once, run in different places

The base image provides Python and Linux userspace. `COPY` puts the package under `/app`. There is no pip install because the application uses only the standard library. `USER 10001:10001` avoids root; a numeric Linux UID works without a named account entry. The exec-form CMD runs Python as the main container process, which is why signals reach it directly.

`EXPOSE` documents a port; it does not publish it. Docker port mapping or a Kubernetes Service provides connectivity. `PYTHONDONTWRITEBYTECODE=1` avoids attempts to write `.pyc` files into the read-only application filesystem.

`python:3.12-slim` is a version-family tag, not an immutable digest. For a production release, resolve and pin a reviewed base digest, scan the image, and record the application image digest. This lab uses `sentinel:local` only for kind; Azure instructions use a git-based tag and deploy the resolved registry digest.

## 8. Kubernetes: desired state and traffic

A Deployment manages ReplicaSets, which keep the desired number of pods running. Deleting one pod causes a replacement; the deleted pod itself does not return. A container crash usually restarts within the same pod. These are different recovery mechanisms.

The Service selects pods with `app: sentinel`; a mismatched label causes no usable endpoints. Service port 80 forwards to container port 8080. `ClusterIP` gives an internal virtual address; it is not an Azure public LoadBalancer.

`kubectl port-forward svc/sentinel 8080:80` tunnels through the Kubernetes API to a selected pod. It is useful for a demo, but its request path does not validate normal in-cluster Service routing or load balancing.

Startup probes allow initial startup time. After startup succeeds, readiness controls whether the pod is eligible for Service traffic; liveness failure can restart the container. The marker file affects readiness only, so a planned drain does not cause a restart loop. See the official probe documentation linked in Azure/reference docs.

Requests reserve scheduling capacity (50m CPU, 64Mi memory per pod). Limits bound consumption (250m, 128Mi): CPU can be throttled; excessive memory can cause OOM kill. `m` means millicores; `Mi` means mebibytes. Capacity for `maxSurge: 1` must exist too.

Rolling update uses `maxUnavailable: 0`, `maxSurge: 1`: start an extra pod before retiring an old one. This helps preserve ready capacity, but does not prove zero downtime. A broken image stalls the update. Kubernetes does not automatically roll it back; our drill explicitly calls `rollout undo`.

Security: restricted namespace policy; UID/GID 10001; no privilege escalation; all Linux capabilities dropped; default seccomp; read-only root; no automatically mounted Kubernetes API token. A writable size-limited `emptyDir` at `/tmp` supports the readiness marker. `emptyDir` is ephemeral and is not a backup or persistent disk.

There is no NetworkPolicy in this lab: other workloads with network access can reach the API. Pod security settings reduce privilege; they do not add authentication or network isolation.

## 9. Azure: map every component

Resource group = lifecycle grouping. ACR = private image storage. AKS = managed Kubernetes control plane plus billable worker infrastructure. Kubelet managed identity = worker-side Azure identity used to pull images. The application itself does not need an Azure credential.

The script chooses registry RBAC mode explicitly because `--attach-acr` uses `AcrPull` on the kubelet identity; ABAC-enabled registry modes use a different permission model. Azure CLI authenticates the operator separately from that workload identity.

The AKS API is restricted to your supplied public IPv4 /32. The application Service remains internal; no public application IP is created. The cluster is not a private AKS cluster: its control-plane endpoint is public but source-restricted. Worker outbound internet access still exists by default. This is a lab posture, not an enterprise landing zone.

Read AZURE.md before creating resources: subscription, quotas, RBAC permissions, billing, region capacity and cleanup all matter.

## 10. CI and evidence

The root workflow checks out the repository, selects Python 3.12, runs tests and ShellCheck, builds the container, creates kind, deploys, checks the HTTP API, runs recovery drills, and uploads cluster evidence. It uses read-only repository permissions and no Azure secrets. It does not deploy to Azure.

The workflow uses versioned action tags for readability; a hardened supply chain should pin reviewed action commit SHAs and verify downloaded binary checksums. Tests and artifacts are evidence for this project, not evidence of professional production experience.

## 11. How to own the project

Reproduce it, read the small Python modules, change a threshold, induce one readiness failure, inspect events, explain the recovery, deploy to your own Azure subscription only after checking costs, and record what actually happened. Once you can do these without copying a script blindly, the repository becomes evidence you can defend.

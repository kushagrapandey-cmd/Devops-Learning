# Interview guide

## Explain it in 60–90 seconds

> CloudOps Sentinel is an operations lab connecting Linux, Bash, Python, Azure and Kubernetes. It checks Linux disk and memory, exposes separate HTTP liveness/readiness endpoints, and turns structured request logs into an error summary. Bash orchestrates host diagnostics and deployment. The application runs as a non-root container with bounded resources and a read-only root filesystem. A Kubernetes Deployment keeps two replicas behind an internal Service. I use a local kind lab to exercise readiness failure, pod replacement and rollback from a broken image release. The repository includes opt-in ACR/AKS scripts and a cleanup procedure. I distinguish executed local tests from Azure deployment evidence rather than treating deployment YAML as proof of a live cloud environment.

Use “I use” or “I reproduced” only once you have actually performed those steps. Until then say “the project includes.” State the current CI/Azure verification status from evidence, not from this sample script.

## Questions you must be able to answer

| Question | Answer |
|---|---|
| Why this project? | It joins operations tasks into a reproducible collect–diagnose–recover–verify workflow. |
| Where is Bash useful? | CLI orchestration, context guards, process exit codes, Linux diagnostics and cleanup traps. |
| Why Python too? | Structured parsing, JSON, testable calculations, HTTP handling and predictable error behavior. |
| Why not one huge shell script? | Python handles structured data clearly; Bash composes existing command-line tools. |
| What is a pod? | Kubernetes scheduling/execution unit containing one or more containers sharing networking and selected volumes. |
| Deployment versus Service? | Deployment manages replicas/releases; Service offers stable discovery and traffic selection. |
| Readiness versus liveness? | Readiness gates Service eligibility; liveness can restart a nonresponsive container. |
| Does Kubernetes automatically roll back? | No. This project detects failed rollout and explicitly invokes undo in the local drill. |
| Two replicas means HA? | Not on one node. Node failure can take both down. |
| Why ClusterIP? | Internal lab access; avoid an unnecessary public endpoint and application load-balancer resource. |
| Is port-forward a load test? | No. It tunnels to one selected pod and does not prove Service load balancing. |
| How does AKS pull from ACR? | Kubelet managed identity gets scoped pull rights through attachment in registry RBAC mode. |
| Why no registry password? | Managed identity handles Azure image pulls; admin credentials are disabled. |
| What does CPU 250m mean? | One quarter of one CPU worth of compute time limit; throttling may occur. |
| Why 128Mi memory limit? | A small lab bound, not performance sizing proven by load tests. Exceeding it may trigger OOM kill. |
| Why separate probes from capacity alerts? | High host load does not prove the app is dead; indiscriminate restarts can worsen the incident. |
| What is actually measured? | Host-visible Linux memory/load and the filesystem containing the configured path. No cgroup usage or historical metrics. |
| How are logs analyzed? | Streaming JSONL, valid status counts, 5xx error percentage, malformed/non-request count. |
| Why no database? | The API is stateless and reports current readings. Persistence is outside the scope. |
| Is this production ready? | No: it lacks authentication/TLS, network isolation, persistent monitoring, multi-node HA and hardened supply-chain controls. |
| Is Azure Free tier free? | The chosen AKS control-plane tier does not eliminate worker, disk, ACR or traffic charges. |
| What tests matter? | Threshold boundaries, invalid input, malformed logs, real HTTP failures/recovery, concurrency, SIGTERM, then cluster recovery drills. |
| What happens if Azure provisioning fails halfway? | Inspect resources; repair deliberately or clean up the dedicated tagged group. The script refuses blind reuse. |

## Skill evidence, not skill-name decoration

| Skill | Concrete evidence in this repository |
|---|---|
| Linux | procfs memory, filesystem metrics, process/socket/uptime reports and permissions |
| Bash | strict mode, quoting, required variables, exit status, traps and CLI orchestration |
| Python | modules, argparse, dictionaries, Counter, streaming files, HTTP, exceptions, tests and signals |
| Azure | ACR/AKS provisioning, subscription guard, managed identity, source restriction and cleanup procedure |
| Kubernetes | Deployment, selectors, Service, probes, resources, security context, updates, events and rollback |
| GitHub Actions | automated tests/build/local cluster smoke checks and evidence artifacts |

Azure scripts demonstrate configuration work. Actual Azure hands-on competence requires deploying and troubleshooting them in a subscription; do not confuse the two.

## Contribution and resume wording

This project was implemented with AI assistance. You can take responsibility for understanding, modifying and validating it; do not invent solo authorship or production ownership. If asked, explain the design choices you reviewed and which exercises you personally ran.

After personally reproducing the local exercises, a defensible resume bullet is:

> Reproduced a Linux/Python operations lab with Bash diagnostics and a containerized Kubernetes health API; investigated readiness failures, pod replacement and failed-release rollback using a local cluster.

Add “deployed to Azure AKS with ACR and managed identity” only after that deployment has happened and you can show sanitized evidence. Do not add fabricated availability gains, incident reductions or production scale.

## Ownership exercises

1. Change the disk threshold and predict the exact exit code at equality.
2. Add a test for a log file containing only 4xx responses.
3. Explain why memory could OOM at 128Mi even though the API reports low host memory pressure.
4. Change readiness path to a nonexistent route locally; use events to diagnose it and restore it.
5. Make a selector mismatch locally; show why the Service has no usable backends.
6. Explain how rolling back differs from fixing the image tag.
7. Recreate the app from a fresh clone and explain each file without reading this guide.
8. Only after local practice, run the Azure lab, collect evidence, remove the resources and verify cleanup.


## Linux VM talking points

Explain why an active service may listen on the wrong port, why localhost success does not establish remote reachability, why enable differs from start, and why app.env backup is not an OS rollback. Show a typed investigation in linux.html and reproduce systemd stop/start on a dedicated Ubuntu VM. Discuss patch prechecks, package review, possible service restarts and post-reboot application validation. The [Hinglish guide](LINUX_VM_LAB.md) gives exact code and commands. Claim Azure deployment or actual patching only after personally completing them.

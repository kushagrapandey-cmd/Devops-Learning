# Operations runbook

Start by confirming context and namespace. Never troubleshoot a production environment by running a destructive demo command.

```bash
kubectl config current-context
kubectl -n sentinel get deploy,pods,svc -o wide
bash scripts/diagnose.sh sentinel
```

| Symptom | Evidence | Likely investigation | Recovery and verification |
|---|---|---|---|
| ImagePullBackOff | Pod describe/events | Wrong image, missing tag, ACR authorization or identity propagation | Correct image/access; wait for rollout and Ready pods |
| CrashLoopBackOff | Logs plus `kubectl logs POD --previous` | Startup exception, incompatible image, permissions or resource limit | Fix root cause; deploy a reviewed image; inspect restart count |
| Pod Pending | Scheduling events | CPU/memory requests, node capacity or taints | Correct requests/capacity; do not remove limits blindly |
| Running but NotReady | `/readyz`, pod conditions | Marker exists or probe path/port failure | Remove local drill marker only if intended; verify Ready |
| OOMKilled | Last container state and events | Container cgroup memory limit exceeded | Measure workload memory, fix leak or resize; host RAM may be fine |
| Service has no ready backends | EndpointSlices, selectors | Label mismatch or readiness failure | Correct selector/probe; verify ready endpoints |
| curl refused locally | Port-forward log, `ss -ltn` | Server/forward not running or port busy | Use a free local port and restart forward |
| Port-forward dies after pod deletion | Forward output and pod UID | Tunnel attached to deleted pod | Re-run port-forward after replacement is Ready |
| Disk warning | Host report and `df -h`, `df -i`, scoped `du` | Filesystem full, inode exhaustion, log growth | Inspect ownership and retention before deletion; check again |
| Memory warning | `free`, process list, cgroup metrics when containerized | Host pressure versus container limit | Identify correct scope; do not assume restart solves capacity |
| Bad rollout stalls | Rollout status and events | New revision never reaches Ready | Inspect; if appropriate `kubectl rollout undo deployment/sentinel -n sentinel`; verify recovery |
| AKS create fails | Azure error, quotas, resource list | Region/size capacity, permissions or partial creation | Inspect existing resources, repair or cleanup; avoid repeated creation |

Pod deletion is not a root-cause fix. Capture logs/events first when evidence matters. No script automatically deletes application data or kills arbitrary host processes.

For Linux service incidents outside this container demo, use `systemctl status SERVICE`, `journalctl -u SERVICE --since ...`, `ss -ltn` and relevant permissions checks. The project does not install a systemd service.

For a real incident record: timestamp (UTC), symptom, affected scope, observations, hypothesis, action, result and follow-up. Do not claim a root cause merely because a restart temporarily helped.


## Linux VM operations

Use [LINUX_VM_LAB.md](LINUX_VM_LAB.md). Investigate systemctl → journal → listener → localhost HTTP → remote path. Backup baseline configuration before a wrong-port drill. Upgrade simulation precedes interactive patching; no helper reboots automatically. A config restore does not reverse package changes. Do not alter the only SSH management path during a network failure exercise.

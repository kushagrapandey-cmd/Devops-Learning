# Build it yourself: understand the code, then reproduce it

## What did we build and why?

CloudOps Sentinel joins an operations toolkit and a browser learning simulator. The toolkit collects real Linux data and runs a Python API on Kubernetes. The Vercel page lets anyone practice incident reasoning without buying Azure resources. The browser does not control a real cluster.

## Build in this order

### 1. Read one Linux metric

```python
import shutil
space = shutil.disk_usage('/')
percent = space.used / space.total * 100
print(round(percent, 2))
```

`disk_usage` asks the OS about one filesystem. `used` and `total` are bytes. Division gives a fraction; multiplying by 100 gives percent. Run it, compare with `df`, and understand reserved-block differences before adding alerts.

### 2. Turn a number into an operational decision

```python
threshold = 85
status = 'warning' if percent >= threshold else 'ok'
```

Equality is intentional: 85 reaches an 85 threshold. Our `health.snapshot()` returns a dictionary so both CLI and HTTP can reuse the calculation. Change a threshold to zero to test an alert without filling a disk.

### 3. Give automation a contract

```bash
bash scripts/host-check.sh --disk-threshold 0
echo $?
```

Expect exit 1 plus JSON alerts. Exit 0 means no threshold warning; exit 2 means invalid input/collection failure. `exec python3 -m sentinel.cli check "$@"` replaces the wrapper process with Python and passes each argument correctly. Quoting prevents accidental splitting.

### 4. Expose HTTP endpoints

Read `make_handler()` in `sentinel/server.py`. `do_GET` routes by URL path. It serializes a Python dictionary with `json.dumps`, sets the response code/content length, then writes bytes to the socket. `/healthz` answers whether the handler responds. `/readyz` checks the marker file. `/api/status` calls the reusable collector.

Run `python3 -m sentinel.server`, then curl each route from another terminal. Create `/tmp/sentinel-not-ready`: readiness becomes 503, liveness stays 200. Remove it: readiness returns 200. Stop with Ctrl+C.

### 5. Package the code

Read the five effective Dockerfile instructions: FROM supplies Python, ENV controls runtime, WORKDIR sets the directory, COPY copies the package, USER changes privileges, CMD launches the module. EXPOSE documents the port. It does not publish it. The container uses a numeric non-root identity.

### 6. Describe desired state

Read `k8s/deployment.yaml`. `replicas: 2` is desired capacity. The selector must match pod labels. Requests influence scheduling; limits constrain runtime resources. A readiness failure removes a pod from normal Service eligibility. A liveness failure can restart a container. The Service selects ready pods using labels and maps port 80 to 8080.

Run `bash scripts/local-cluster.sh`, inspect pods, and port-forward. Stop port-forward before `bash scripts/drills.sh`: a tunnel can be attached to the pod the drill deletes. The drill checks readiness failure/recovery, pod replacement and rollback from a missing image.

### 7. Understand the browser state machine

Read `web/assets/model.js`. `initialState()` creates healthy state. `transition(state, action)` copies it and applies only allowed transitions. `recover` is ignored until diagnosis. `view()` calculates the visible pod/backend state. `execute()` matches an allowlist of simulated commands; it never executes shell text.

`app.js` connects buttons to transitions and renders the result. Variable text uses `textContent`; it is not interpreted as HTML. Local storage saves progress on that browser. Export creates a JSON Blob explicitly labelled simulation. These are browser functions, separate from Python and Kubernetes.

### 8. Add tests before adding complexity

```bash
bash scripts/verify.sh
node --test tests/model.test.mjs
```

Python tests check real HTTP requests, failure recovery, malformed logs, exact alert thresholds, concurrency and SIGTERM shutdown. Bash guard tests verify that wrong contexts and missing opt-in flags fail before mutation. JavaScript tests check all four scenario lifecycles, invalid saved data and unsupported commands.

## Manual acceptance checklist

1. Open the live page: healthy replicas show 2/2; Diagnose/Recover are disabled.
2. Inject readiness failure: replicas drop to 1/2; liveness concept remains healthy.
3. Diagnose: root cause appears; Recover enables.
4. Recover: replicas return to 2/2; evidence timeline records recovery.
5. Broken image: old replicas stay ready despite the failed new revision.
6. Selector mismatch: pods stay Ready, but Service backends become zero.
7. Memory failure: explanation distinguishes host memory from container limits.
8. Terminal: type `help`, a supported command and an unsupported command. Unsupported input must never execute.
9. Reload: selected scenario/phase restores. Reset returns to initial healthy state.
10. Download report: JSON identifies itself as simulated evidence.

## Azure and Vercel are different jobs

Vercel serves static HTML/CSS/JavaScript. It is not running the AKS cluster or the long-lived Python HTTP server in this project. Azure scripts create ACR and AKS only after explicit billable-resource opt-in, then deploy an image digest. Read AZURE.md for permissions, source-IP restrictions and cleanup. No Azure deployment has been performed by this build.

## Your independent rebuild challenge

Create a fresh directory. Implement disk percentage and one test without copying. Add JSON CLI output and exit codes. Add the three HTTP endpoints. Containerize. Add Deployment/Service/probes. Reproduce one failure and write what you observed. Finally build a tiny simulator with healthy/injected/diagnosed/recovered states. Compare with this repository only after each attempt. This demonstrates understanding more reliably than memorizing the README.


## Build the Linux VM module yourself

[The Hinglish Linux guide](LINUX_VM_LAB.md) explains service supervision, environment variables, loopback binding, SSH tunnels, backup scope, apt maintenance and Bicep. Rebuild in this order: manual Python → systemd → HTTP validation → deliberate service/config failure → backup/restore → patch planning → optional Azure VM. Website simulator commands are teaching shortcuts; use the guide mappings for real execution.

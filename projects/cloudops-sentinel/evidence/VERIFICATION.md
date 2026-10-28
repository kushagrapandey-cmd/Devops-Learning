# Verification — 28 October 2026

Live demo: https://cloudops-sentinel-three.vercel.app/

Verified code commit: b3f2a28ead8b37d9680ede53a199ae265282ca79

[Successful GitHub Actions run](https://github.com/kushagrapandey-cmd/Devops-Learning/actions/runs/40572500017)

- 20 Python/HTTP integration and Bash guard tests: passed.
- 12 JavaScript simulation tests: passed.
- ShellCheck: passed.
- Docker image build and real kind Kubernetes deployment: passed.
- HTTP readiness and status smoke checks through port-forward: passed.
- Readiness failure and recovery: passed.
- Deleted-pod replacement: passed.
- Deliberately missing image rollout failure and explicit rollback: passed.
- Cluster evidence uploaded by CI (7-day artifact retention; workflow logs retain the run evidence).
- Deployed browser QA: all four inject/diagnose/recover flows, terminal help, reload state restoration, reset and report download passed. Desktop layout inspected. Mobile device testing was not performed.
- Vercel production deployment READY. Browser accessed the production URL without a sign-in screen. No Azure deployment claimed.

## Findings corrected during testing

First deployment initially produced an empty rendered Deployment when kubectl set image received the existing image name. Rendering now writes the manifest explicitly. After successful rollback, a broad pod wait initially raced with deletion of old-revision pods. Verification now uses the current Deployment rollout status.

## Limits

Browser metrics are simulation values, not cloud telemetry. Real Kubernetes testing used kind on a GitHub runner, not AKS. Azure scripts need subscription-specific quota, identity, network and billing validation. Full Linux host triage could not run in the build container because ps/ss operations are restricted there. No load benchmark, production availability guarantee or mobile-browser certification is claimed.

## Learn and reproduce

Read [Build it yourself](../docs/BUILD_IT_YOURSELF.md), [code walkthrough](../docs/WALKTHROUGH.md), [demo tests](../docs/DEMO.md), and [Azure lab](../docs/AZURE.md).


## Linux VM extension — 28 October 2026

Code commit: 48be4bf373499d6e3ece1e8ce70f793a3d47d718.

[Full passing CI run](https://github.com/kushagrapandey-cmd/Devops-Learning/actions/runs/40630571493).

- 20 Python/HTTP/guard tests and 18 JavaScript model tests passed.
- ShellCheck passed for original and new Linux/Azure scripts.
- Azure VM Bicep compiled successfully; compilation is not cloud deployment validation.
- Real systemd application install, HTTP precheck, stop/start recovery, wrong-port configuration change, backup/restore and apt upgrade simulation passed on Ubuntu GitHub runner.
- Original Docker/kind deployment, HTTP smoke and Kubernetes recovery/rollback passed.
- Live browser: all four Linux command-driven assignments passed; premature recovery rejected; remote verification required for NSG case; patch/reboot simulation, transcript download and reset passed.
- Vercel production READY: https://cloudops-sentinel-three.vercel.app/linux.html
- No actual Azure VM creation, paid resources, OS package upgrades, real reboot, physical power outage, mobile device QA or remote NSG injection performed. Simulator outputs are teaching examples. The real app uses loopback plus SSH tunnel, unlike the hypothetical public application path in the NSG assignment.

All learning guides now reference the full Hinglish Linux guide at docs/LINUX_VM_LAB.md.

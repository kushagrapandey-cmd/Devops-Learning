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

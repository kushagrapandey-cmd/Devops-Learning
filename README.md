# Systems and Automation Reference

Linux administration, Bash/Python automation and reproducible infrastructure labs.

## Featured project: CloudOps Sentinel

[Project README](projects/cloudops-sentinel/README.md) · [Live website](https://cloudops-sentinel-three.vercel.app/) · [Linux VM workbench](https://cloudops-sentinel-three.vercel.app/linux.html)

CloudOps Sentinel connects Linux operations, Python/Bash tooling, systemd, Docker, Kubernetes and optional Azure infrastructure in one project.

- **Linux VM lab:** real systemd installation, service/port diagnosis, baseline configuration backup/restore and guarded patch planning.
- **Python toolkit:** Linux resource snapshots, structured HTTP endpoints and JSON log summaries.
- **Kubernetes lab:** two replicas, health probes, resource/security settings, pod replacement and failed-release rollback.
- **Azure source:** optional AKS/ACR scripts plus Ubuntu VM Bicep with VNet, subnet, NSG, NIC, SSH-key access and cleanup procedures.
- **One website, two pages:** a Kubernetes incident simulator and a command-driven Linux workbench with evidence gates and transcript export.
- **CI:** Python/JavaScript tests, ShellCheck, Bicep compilation, real Ubuntu systemd exercises and Docker/kind recovery checks.

Browser outputs are simulations. Azure provisioning source is included, but no live Azure deployment is claimed. See [verification evidence](projects/cloudops-sentinel/evidence/VERIFICATION.md).

## Start here

1. [Hinglish Linux guide](projects/cloudops-sentinel/docs/LINUX_VM_LAB.md): commands, code explanations, expected results and real VM setup.
2. [Build it yourself](projects/cloudops-sentinel/docs/BUILD_IT_YOURSELF.md): recreate the project step by step.
3. [Code walkthrough](projects/cloudops-sentinel/docs/WALKTHROUGH.md): responsibilities and architecture.
4. [Demo exercises](projects/cloudops-sentinel/docs/DEMO.md) and [interview guide](projects/cloudops-sentinel/docs/INTERVIEW.md).

```bash
git clone https://github.com/kushagrapandey-cmd/Devops-Learning.git
cd Devops-Learning/projects/cloudops-sentinel
bash scripts/verify.sh
python3 -m sentinel.server
```

Python-only execution requires Linux/WSL, Python 3.12+ and Bash. See the project README for additional prerequisites for systemd, JavaScript tests, containers and Azure.

## Bash fundamentals example

[`scripts/bash/my_first_bashScript.sh`](scripts/bash/my_first_bashScript.sh) demonstrates system information, variables, string operations and positional arguments.

```bash
bash scripts/bash/my_first_bashScript.sh example
```

Read the script first. It prints system/string examples with a short pause; it does not provision infrastructure.

## Navigation

| Directory | Purpose |
| --- | --- |
| `projects/cloudops-sentinel/` | Implemented operations project, application source, infrastructure, tests and guides |
| `scripts/bash/` | Standalone Bash fundamentals example |
| `scripts/python/` | Reference section; implemented project Python lives under CloudOps Sentinel |
| `study-material/` | Topic reference sections |
| `labs/` | Linux, networking and Azure reference sections |
| `cheatsheets/` | Quick-reference section |
| `resources/` | External-reference section |

Reference folders may contain section README files rather than executable labs. The CloudOps Sentinel folder contains the implemented project. This repository currently has no Terraform implementation.

## Application projects

- [MediConnect](https://github.com/kushagrapandey-cmd/mediconnect)
- [YTGuide](https://github.com/kushagrapandey-cmd/First_ML_project)
- [WWW-of-Anime](https://github.com/kushagrapandey-cmd/WWW-of-Anime)

# DevOps Learning Journey

This repository documents my hands-on journey from Linux fundamentals to practical DevOps engineering.

It is my central learning workspace for notes, scripts, labs, cheatsheets, troubleshooting exercises, study material, and small projects across Linux, networking, cloud, automation, and modern DevOps tools.

The goal is not just to collect theory. I want this repository to show what I actually study, practice, automate, troubleshoot, and build over time.

---

## Learning Roadmap

My current learning path is organized roughly in this order:

1. **Linux Fundamentals & Administration**
   - Filesystem and command line
   - Users, groups, permissions, and ownership
   - Processes, services, logs, storage, and system resources
   - Package management and troubleshooting

2. **Networking Fundamentals**
   - TCP/IP and the OSI model
   - IP addressing and subnetting
   - DNS, DHCP, SSH, NAT, routing, and ports
   - Linux networking commands and troubleshooting

3. **Cloud & Microsoft Azure**
   - Cloud fundamentals
   - Azure architecture and core services
   - Compute, storage, networking, identity, and security
   - Monitoring, backup, disaster recovery, and administration

4. **Scripting & Automation**
   - Bash scripting
   - Python for automation
   - Command-line automation
   - File, process, monitoring, and system administration scripts

5. **Git & GitHub**
   - Version control fundamentals
   - Branching and commits
   - Remote repositories
   - Collaboration workflows

6. **DevOps Core**
   - Docker
   - Terraform
   - CI/CD
   - GitHub Actions / Azure DevOps
   - Kubernetes and AKS
   - Monitoring and observability

7. **Hands-on Projects**
   - Linux administration projects
   - Automation utilities
   - Cloud infrastructure
   - Containerized applications
   - CI/CD pipelines
   - Infrastructure as Code
   - Kubernetes deployments

---

## Repository Structure

```text
Devops-Learning/
├── README.md
│
├── scripts/
│   ├── bash/
│   └── python/
│
├── study-material/
│   ├── linux/
│   ├── networking/
│   ├── git-github/
│   ├── cloud-azure/
│   └── devops/
│       ├── docker/
│       ├── terraform/
│       ├── cicd/
│       ├── kubernetes/
│       └── monitoring/
│
├── labs/
│   ├── linux/
│   ├── networking/
│   └── azure/
│
├── cheatsheets/
├── projects/
└── resources/
```

---

## How I Use This Repository

### `scripts/`

Contains scripts I write while learning automation and system administration.

- `scripts/bash/` — Bash scripts
- `scripts/python/` — Python automation scripts

Scripts will range from simple learning exercises to practical utilities for monitoring, file management, system administration, networking, and DevOps automation.

### `study-material/`

Contains topic-wise learning material and notes.

```text
study-material/
├── linux/
├── networking/
├── git-github/
├── cloud-azure/
└── devops/
    ├── docker/
    ├── terraform/
    ├── cicd/
    ├── kubernetes/
    └── monitoring/
```

This can include Markdown notes, diagrams, PDFs, references, examples, and summaries created during study.

### `labs/`

Contains hands-on exercises and experiments.

Examples:

- Linux command practice
- Process and service troubleshooting
- Network troubleshooting
- Azure administration exercises
- Configuration experiments
- Command outputs and observations

### `cheatsheets/`

Quick-reference material that I want to revise frequently, such as:

- Important Linux commands
- Common command options
- Ports and protocols
- Networking commands
- Git commands
- Bash syntax
- Terraform commands
- Docker commands
- Kubernetes commands

### `projects/`

Contains practical projects that combine multiple concepts instead of isolated exercises.

The complexity of these projects will increase as my DevOps knowledge improves.

### `resources/`

Useful external learning references such as documentation, books, courses, articles, and other resources.

---

## Current Foundation: Linux

Linux is the first major foundation of this journey because many DevOps tools and production systems depend heavily on Linux concepts.

### Core Topics

- Linux filesystem hierarchy
- File and directory management
- Text processing
- Users and groups
- Permissions and ownership
- Processes and jobs
- Services and `systemd`
- Logs
- Storage and disk usage
- CPU and memory monitoring
- Networking
- Package management
- Shell scripting
- Input/output redirection
- Pipes and text-processing tools such as `grep`, `sed`, and `awk`

---

## Bash Learning

Bash scripts are stored in:

```text
scripts/bash/
```

Topics I will practice include:

- Variables
- User input
- Positional parameters
- Exit codes
- Conditional statements
- `case` statements
- Loops
- Functions
- Arrays
- File operations
- Input/output redirection
- Pipes
- Process management
- Log processing
- System monitoring
- Networking utilities
- Automation
- Scheduled tasks
- Backup and maintenance scripts

---

## Python for DevOps

Python scripts are stored in:

```text
scripts/python/
```

The focus will be practical automation rather than Python for its own sake.

Planned areas include:

- File and directory automation
- System information collection
- Log parsing
- Process monitoring
- Network automation
- API interaction
- JSON/YAML processing
- Cloud automation
- DevOps utilities

---

## Git Workflow

For each meaningful learning change, I try to follow:

```text
Learn / Build
     ↓
Test
     ↓
git status
     ↓
git add
     ↓
git diff --cached
     ↓
git commit
     ↓
git push
```

Commit messages should describe the actual learning or change, for example:

```text
add first Bash practice script
practice Bash conditional statements
add Linux process monitoring notes
add networking subnetting lab
add Docker container networking notes
build disk usage monitoring script
```

The purpose is to maintain a useful history of progress, not to generate meaningless commits only for activity.

---

## Progress Philosophy

- Learn concepts deeply enough to explain them.
- Practice commands instead of only reading about them.
- Keep small scripts and examples that demonstrate what I learned.
- Document mistakes and troubleshooting steps.
- Revisit earlier concepts regularly.
- Gradually turn isolated skills into complete projects.
- Keep the repository organized enough that I can use it later as my own reference.

---

## Long-Term Goal

The long-term goal of this repository is to document my progression from:

```text
Linux Fundamentals
        ↓
Networking
        ↓
Cloud / Azure
        ↓
Bash & Python Automation
        ↓
Git
        ↓
Docker
        ↓
Terraform
        ↓
CI/CD
        ↓
Kubernetes / AKS
        ↓
Monitoring & Observability
        ↓
Practical DevOps Projects
```

This repository will evolve alongside my learning, with real notes, scripts, labs, and projects added as I complete them.

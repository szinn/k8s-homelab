---
description: Tool strategy covering MCP servers, CLI commands, and exploration patterns for k8s-homelab
tags: ["MermaidValidation", "TaskfileCLI", "FluxCLI", "KubectlCLI", "TalosctlCLI"]
audience: ["LLMs", "Humans"]
categories: ["Reference[100%]", "Tools[95%]"]
---

# Tool Strategy

**Principle**: Query before reading. Use structured tools to understand scope, then drill down.

**Context**: This homelab manages TWO independent Kubernetes clusters (main and staging) using GitOps. Most commands require explicit cluster context.

---

## MCP Servers

Configured in `@.mcp.json`:

### GitHub

**Purpose**: Pull request management, issue tracking, and GitHub operations.

**Configuration**:

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp",
      "headers": {
        "Authorization": "Bearer ${CLAUDE_GITHUB_PAT}"
      }
    }
  }
}
```

**Use For**:

- Creating and managing pull requests
- Issue tracking and management
- Repository operations

**Requires**: `CLAUDE_GITHUB_PAT` environment variable with a valid GitHub personal access token.

### Mermaid Validator

**Purpose**: Validate and auto-fix Mermaid diagrams.

**Configuration**:

```json
{
  "mcpServers": {
    "mermaid": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@probelabs/maid-mcp"]
    }
  }
}
```

**Use For**:

- Validating diagrams in documentation
- Auto-fixing syntax errors before commit
- See @docs/ai-context/mermaid-diagram-guide.md for diagram standards

**Potential Future MCP Servers**:

- **Filesystem MCP**: Enhanced file operations and searches
- **RepoQL**: Query codebase as database (semantic search, file inventory)

---

## CLI Tools

### Taskfile (go-task)

**Location**: `Taskfile.yaml`, `.taskfiles/`

**Discovery**:

```bash
task --list                    # See all available tasks
task --list-all                # Include internal tasks
task <namespace>: --list       # List tasks in specific namespace
```

#### Quick Reference

| Command                                                               | Purpose                     | Cluster   |
| --------------------------------------------------------------------- | --------------------------- | --------- |
| `task configure`                                                      | Render Jinja2 templates     | Both      |
| `task kubernetes:kubeconform cluster=main`                            | Validate manifests          | Specified |
| `task kubernetes:delete-failed-pods cluster=main`                     | Clean up failed pods        | Specified |
| `task kubernetes:approve-certs cluster=staging`                       | Approve pending CSRs        | Specified |
| `task kubernetes:netshoot cluster=main`                               | Run netshoot debug pod      | Specified |
| `task flux:sync cluster=main`                                         | Sync flux-cluster with Git  | Specified |
| `task flux:gr-sync cluster=staging`                                   | Sync GitRepositories        | Specified |
| `task flux:ks-sync cluster=main`                                      | Sync Kustomizations         | Specified |
| `task flux:hr-sync cluster=main`                                      | Sync HelmReleases           | Specified |
| `task flux:force-hr-sync cluster=staging`                             | Force sync with reset       | Specified |
| `task sops:re-encrypt`                                                | Re-encrypt all SOPS files   | Both      |
| `task volsync:snapshot cluster=main app=immich ns=media`              | Trigger backup snapshot     | Specified |
| `task volsync:restore cluster=main app=immich ns=media previous=<id>` | Restore from backup         | Specified |
| `task volsync:unlock cluster=main`                                    | Unlock Restic repos         | Specified |
| `task postgres:maintenance-main command=set`                          | Set maintenance mode        | Main      |
| `task postgres:down_immich`                                           | Suspend Immich app          | Main      |
| `task postgres:up_immich`                                             | Resume Immich app           | Main      |
| `task pre-commit:init`                                                | Initialize pre-commit hooks | Both      |
| `task pre-commit:run`                                                 | Run pre-commit checks       | Both      |
| `task format:all`                                                     | Format all files            | Both      |

#### Flux Tasks

**File**: `.taskfiles/Flux/Taskfile.yaml`

```bash
# Sync entire cluster with Git
task flux:sync cluster=main

# Sync all GitRepositories
task flux:gr-sync cluster=staging

# Sync all Kustomizations
task flux:ks-sync cluster=main

# Sync all HelmReleases
task flux:hr-sync cluster=staging

# Force sync with reset (destructive)
task flux:force-hr-sync cluster=main

# Suspend/resume all HelmReleases
task flux:hr-suspend cluster=main
task flux:hr-resume cluster=staging
```

**Pattern**: All flux tasks require `cluster=<main|staging>` parameter.

#### Kubernetes Tasks

**File**: `.taskfiles/Kubernetes/Taskfile.yaml`

```bash
# Validate manifests with kubeconform
task kubernetes:kubeconform cluster=main

# Clean up failed/evicted/succeeded pods
task kubernetes:delete-failed-pods cluster=staging

# Approve pending certificate signing requests
task kubernetes:approve-certs cluster=main

# Debug tools
task kubernetes:netshoot cluster=main    # Network debugging
task kubernetes:alpine cluster=main      # Alpine container
task kubernetes:ubuntu cluster=main      # Ubuntu container

# Operations
task kubernetes:what-dockerhub cluster=main           # List Docker Hub images
task kubernetes:redeploy-ingresses cluster=main       # Restart ingress controllers
task kubernetes:redeploy-daemonsets cluster=main      # Restart all daemonsets
```

#### SOPS Tasks

**File**: `.taskfiles/Sops/Taskfile.yaml`

```bash
# Re-encrypt all *.sops.yaml files (after key rotation)
task sops:re-encrypt
```

**Pattern**: Finds all `*.sops.yaml` files, decrypts, then re-encrypts with current keys.

#### Volsync Tasks

**File**: `.taskfiles/Volsync/Taskfile.yaml`

```bash
# List snapshots
task volsync:list cluster=main app=immich ns=media

# Create snapshot
task volsync:snapshot cluster=main app=immich ns=media

# Create all snapshots (parallel)
task volsync:snapshot-all cluster=main

# Restore from snapshot
task volsync:restore cluster=main app=immich ns=media previous=<snapshot-id>

# Unlock stuck Restic repositories
task volsync:unlock cluster=main
```

**Requirements**:

- Assumes ReplicationSource exists with same name as app
- Assumes single PVC per app
- For restore: suspends app, restores data, resumes app

#### Postgres Tasks

**File**: `.taskfiles/Postgres/Taskfile.yaml`

```bash
# Maintenance mode (for upgrades)
task postgres:maintenance-main command=set
task postgres:maintenance-main command=unset
task postgres:maintenance-staging command=set

# Application control (main cluster only)
task postgres:down_immich        # Suspend Immich
task postgres:up_immich          # Resume Immich
task postgres:restore_immich     # Restore database from backup
```

**Pattern**: Database operations primarily target main cluster where CloudNativePG runs.

#### Pre-commit Tasks

**File**: `.taskfiles/Pre-commit/Taskfile.yaml`

```bash
# Initialize hooks
task pre-commit:init

# Update hook versions
task pre-commit:update

# Run all hooks
task pre-commit:run
```

#### Format Tasks

**File**: `.taskfiles/Format/Taskfile.yaml`

```bash
# Format all
task format:all

# Format specific types
task format:markdown
task format:yaml
task format:terraform
task format:just
```

#### Machine Tasks

**File**: `.taskfiles/Machine/Taskfile.yaml`

**Purpose**: Manage non-Kubernetes infrastructure (DNS servers, certificate distribution, etc.)

```bash
# Certificate management
task machine:fetch-certificate              # Fetch from cluster
task machine:update-certificates            # Deploy to all machines

# AdGuard DNS updates
task machine:update-artemis-configuration
task machine:update-apollo-configuration

# System updates
task machine:update-linux-packages
```

---

## Capsule: ClusterContextRequirement

**Invariant**: Almost all kubectl, flux, and talosctl commands require explicit cluster context.

**Why**: This repo manages two independent clusters with different purposes and infrastructure.

**Pattern**:

- **kubectl**: `kubectl --context <main|staging> <command>`
- **flux**: `flux --context <main|staging> <command>`
- **talosctl**: `talosctl --talosconfig kubernetes/<main|staging>/talosconfig <command>`
- **task**: `task <namespace>:<command> cluster=<main|staging>` (for cluster-specific tasks)

**Kubeconfig Locations**:

- Main cluster: `kubernetes/main/kubeconfig`
- Staging cluster: `kubernetes/staging/kubeconfig`

**Talosconfig Locations**:

- Main cluster: `kubernetes/main/talosconfig`
- Staging cluster: `kubernetes/staging/talosconfig`

**Evidence**:

| Claim                               | Source                                                                 | Confidence |
| ----------------------------------- | ---------------------------------------------------------------------- | ---------- |
| Two independent clusters exist      | `kubernetes/main/` and `kubernetes/staging/` directories               | Verified   |
| Taskfiles require cluster parameter | `.taskfiles/Flux/Taskfile.yaml`, `.taskfiles/Kubernetes/Taskfile.yaml` | Verified   |
| Separate kubeconfigs per cluster    | `kubernetes/main/kubeconfig`, `kubernetes/staging/kubeconfig`          | Verified   |

---

## Flux CLI

| Command                                                               | Purpose                  |
| --------------------------------------------------------------------- | ------------------------ |
| `flux get kustomizations --context <main\|staging>`                   | List all kustomizations  |
| `flux get helmreleases -A --context <main\|staging>`                  | List all HelmReleases    |
| `flux get helmrelease <name> -n <ns> --context <main\|staging>`       | Check specific release   |
| `flux reconcile kustomization <name> --context <main\|staging>`       | Force sync kustomization |
| `flux reconcile helmrelease <name> -n <ns> --context <main\|staging>` | Force sync HelmRelease   |
| `flux reconcile source git flux-system --context <main\|staging>`     | Sync Git source          |
| `flux logs --context <main\|staging>`                                 | View controller logs     |
| `flux suspend helmrelease <name> -n <ns> --context <main\|staging>`   | Suspend release          |
| `flux resume helmrelease <name> -n <ns> --context <main\|staging>`    | Resume release           |

**Pattern**: Flux operations ALWAYS need `--context <main|staging>`.

**Common Workflows**:

```bash
# Check cluster status (specify cluster)
flux get kustomizations --context <main|staging>
flux get helmreleases -A --context <main|staging>

# Force reconciliation (specify cluster)
flux reconcile source git flux-system --context <main|staging>
flux reconcile kustomization cluster-apps --context <main|staging>

# Debug failed release (specify cluster)
flux get hr <name> -n <namespace> --context <main|staging>
kubectl logs -n flux-system deploy/helm-controller --context <main|staging> | grep <name>
```

---

## kubectl

| Command                                                                    | Purpose                 |
| -------------------------------------------------------------------------- | ----------------------- |
| `kubectl get pods -A --context <main\|staging>`                            | List all pods           |
| `kubectl get hr -A --context <main\|staging>`                              | List HelmReleases       |
| `kubectl logs -n <ns> <pod> --context <main\|staging>`                     | View pod logs           |
| `kubectl describe hr <name> -n <ns> --context <main\|staging>`             | HelmRelease details     |
| `kubectl get events -A --sort-by=.lastTimestamp --context <main\|staging>` | Recent events           |
| `kubectl get pvc -A --context <main\|staging>`                             | List persistent volumes |
| `kubectl get externalsecrets -A --context <main\|staging>`                 | List external secrets   |

**Pattern**: All kubectl operations REQUIRE `--context <main|staging>`.

**Cluster-Specific Operations**:

```bash
# Main cluster (physical hardware)
kubectl get nodes --context main

# Staging cluster (Proxmox VMs)
kubectl get nodes --context staging

# Explicit kubeconfig (optional, context is usually sufficient)
kubectl --context main --kubeconfig kubernetes/main/kubeconfig get nodes
kubectl --context staging --kubeconfig kubernetes/staging/kubeconfig get nodes
```

---

## talosctl

**Purpose**: Manage Talos Linux nodes for both clusters.

**Configuration Files**:

- Main: `kubernetes/main/talosconfig`
- Staging: `kubernetes/staging/talosconfig`

| Command                                                                         | Purpose         |
| ------------------------------------------------------------------------------- | --------------- |
| `talosctl --talosconfig kubernetes/<main\|staging>/talosconfig dashboard`       | Node dashboard  |
| `talosctl --talosconfig kubernetes/<main\|staging>/talosconfig health`          | Cluster health  |
| `talosctl --talosconfig kubernetes/<main\|staging>/talosconfig logs -f kubelet` | Node logs       |
| `talosctl --talosconfig kubernetes/<main\|staging>/talosconfig get members`     | Cluster members |
| `talosctl --talosconfig kubernetes/<main\|staging>/talosconfig upgrade`         | Upgrade nodes   |
| `talosctl --talosconfig kubernetes/<main\|staging>/talosconfig reset`           | Reset node      |

**Pattern**: Always specify `--talosconfig kubernetes/<main|staging>/talosconfig` path for explicit cluster targeting.

**Common Operations**:

```bash
# Check cluster health (main)
talosctl --talosconfig kubernetes/main/talosconfig health

# Check cluster health (staging)
talosctl --talosconfig kubernetes/staging/talosconfig health

# View node logs (specify cluster)
talosctl --talosconfig kubernetes/<main|staging>/talosconfig logs -f kubelet

# Get node configuration (specify cluster)
talosctl --talosconfig kubernetes/<main|staging>/talosconfig get machineconfig
```

---

## Discovery Patterns

### Understanding the Repository

```bash
# Via CLI
task --list                          # See available tasks
ls kubernetes/main/apps/             # See main cluster namespaces
ls kubernetes/staging/apps/          # See staging cluster namespaces
ls kubernetes/main/apps/<namespace>/ # See apps in namespace

# Via documentation
cat docs/ai-context/ARCHITECTURE.md  # System architecture
cat docs/ai-context/CONVENTIONS.md   # Coding standards
cat .claude/CLAUDE.md                # Quick reference
```

### Finding an App

```bash
# Via directory structure
ls kubernetes/main/apps/media/       # Apps in media namespace (main cluster)
ls kubernetes/staging/apps/media/    # Apps in media namespace (staging cluster)

# Via grep
grep -r "app: immich" kubernetes/main/apps/     # Search main cluster
grep -r "app: immich" kubernetes/staging/apps/  # Search staging cluster

# Via flux
flux get hr -A --context main | grep immich     # Search main cluster
flux get hr -A --context staging | grep immich  # Search staging cluster
```

### Checking Deployment Status

```bash
# Flux status (specify cluster)
flux get hr immich -n media --context <main|staging>

# Pod status (specify cluster)
kubectl get pods -n media -l app.kubernetes.io/name=immich --context <main|staging>

# Events (specify cluster)
kubectl get events -n media --field-selector involvedObject.name=immich --context <main|staging> --sort-by=.lastTimestamp
```

### Debugging a Failure

```bash
# 1. Check HelmRelease status
flux get hr <name> -n <namespace> --context <main|staging>

# 2. Describe HelmRelease
kubectl describe hr <name> -n <namespace> --context <main|staging>

# 3. View Flux controller logs
kubectl logs -n flux-system deploy/helm-controller --context <main|staging> | grep <name>

# 4. Check pod events
kubectl describe pod -n <namespace> -l app.kubernetes.io/name=<name> --context <main|staging>

# 5. View pod logs
kubectl logs -n <namespace> -l app.kubernetes.io/name=<name> --context <main|staging>

# 6. Check external secrets
kubectl get externalsecrets -n <namespace> --context <main|staging>
kubectl describe externalsecret <name> -n <namespace> --context <main|staging>
```

### Validating Changes

```bash
# Before commit
task configure                          # Render templates
task kubernetes:kubeconform cluster=main   # Validate main cluster
task kubernetes:kubeconform cluster=staging # Validate staging cluster
task pre-commit:run                     # Run all pre-commit hooks

# After push (check reconciliation)
flux get kustomizations --context <main|staging>
flux get helmreleases -A --context <main|staging>
```

---

## Quick Reference

### When to Use What

| Task                      | Tool                                                                                   |
| ------------------------- | -------------------------------------------------------------------------------------- |
| Understand repo structure | `task --list`, directory navigation                                                    |
| Find specific pattern     | `grep -r` or `Grep` tool                                                               |
| Read a file               | `Read` tool or `cat`                                                                   |
| Validate YAML             | `task kubernetes:kubeconform cluster=<main\|staging>`                                  |
| Check cluster state       | `flux get` / `kubectl get` with `--context`                                            |
| Debug app                 | `kubectl logs` / `kubectl describe` with `--context`                                   |
| Force deployment          | `task flux:sync cluster=<main\|staging>`                                               |
| Render templates          | `task configure` (no cluster needed)                                                   |
| Create backup             | `task volsync:snapshot cluster=<main\|staging> app=<name> ns=<namespace>`              |
| Restore backup            | `task volsync:restore cluster=<main\|staging> app=<name> ns=<namespace> previous=<id>` |

### Common Command Patterns

#### Template Workflow

```bash
# 1. Edit templates in bootstrap/templates/
# 2. Render with Jinja2
task configure

# 3. Validate
task kubernetes:kubeconform cluster=main
task kubernetes:kubeconform cluster=staging

# 4. Commit (pre-commit hooks run automatically)
git add .
git commit -m "feat: Add new application"
```

#### Deployment Workflow

```bash
# 1. Push to Git
git push

# 2. Check Flux picks up changes
flux get source git flux-system --context <main|staging>

# 3. Force reconciliation if needed
task flux:sync cluster=<main|staging>

# 4. Monitor deployment
flux get hr -A --context <main|staging>
kubectl get pods -A --context <main|staging>
```

#### Troubleshooting Workflow

```bash
# 1. Identify failed resource
flux get hr -A --context <main|staging>

# 2. Check HelmRelease details
kubectl describe hr <name> -n <namespace> --context <main|staging>

# 3. Check controller logs
kubectl logs -n flux-system deploy/helm-controller --context <main|staging> | grep <name>

# 4. Check pod logs
kubectl logs -n <namespace> -l app.kubernetes.io/name=<name> --context <main|staging>

# 5. Force reconciliation
flux reconcile hr <name> -n <namespace> --context <main|staging> --force
```

---

## Environment Setup

### Required for Full Functionality

**Direnv** (recommended):

```bash
# Enable direnv
direnv allow .

# This loads:
# - SOPS decryption keys from config.sops.env
# - DBBACKUP path for postgres operations
# - REPO_ROOT for scripts
# - MINIJINJA_CONFIG_FILE for template rendering
```

**Manual Setup**:

```bash
# Kubeconfig for cluster access
export KUBECONFIG=~/k8s-homelab/kubernetes/main/kubeconfig     # Main cluster
export KUBECONFIG=~/k8s-homelab/kubernetes/staging/kubeconfig  # Staging cluster

# SOPS age key for secret decryption
export SOPS_AGE_KEY_FILE=~/k8s-homelab/age.key

# Template rendering
export MINIJINJA_CONFIG_FILE=~/k8s-homelab/.minijinja.toml

# Database backups (main cluster)
export DBBACKUP=~/Ragnar/k8s/main/backup/dbms
```

**Direnv Configuration** (`.envrc`):

```bash
use_sops() {
  local path=${1:-$PWD/secrets.yaml}
  eval "$(sops -d --output-type dotenv "$path" | direnv dotenv bash /dev/stdin)"
  watch_file "$path"
}

export DBBACKUP=$HOME/Ragnar/k8s/main/backup/dbms
export REPO_ROOT=$(git rev-parse --show-toplevel)
export MINIJINJA_CONFIG_FILE="${REPO_ROOT}/.minijinja.toml"
export TASK_X_MAP_VARIABLES=0

use_sops config.sops.env
```

---

## Pre-commit Hooks

**Configuration**: `.pre-commit-config.yaml`

**Installed Hooks**:

- **forbid-yml**: Enforce `.yaml` extension (not `.yml`)
- **yamllint**: YAML syntax validation
- **check-added-large-files**: Prevent large file commits (max 2MB)
- **check-merge-conflict**: Detect merge conflict markers
- **end-of-file-fixer**: Ensure newline at EOF
- **trailing-whitespace**: Remove trailing whitespace
- **forbid-crlf**: Enforce LF line endings
- **forbid-tabs**: Enforce spaces (not tabs)
- **forbid-secrets**: Prevent unencrypted secrets (via SOPS)
- **markdownlint**: Markdown formatting
- **shellcheck**: Shell script validation

**Usage**:

```bash
# Initialize (one-time setup)
task pre-commit:init

# Run manually
task pre-commit:run

# Update hook versions
task pre-commit:update

# Auto-run on git commit (after init)
git commit -m "message"  # Hooks run automatically
```

**SOPS Secret Detection**:

- Files ending in `.sops.yaml` must be encrypted
- Prevents accidental secret leaks
- Configured in `.sops.yaml` for encryption rules

---

## Tool Version Management

**Note**: This project does not currently use `mise` or `.tool-versions` for version management.

**Tool Installation**:
Tools are expected to be installed via system package managers:

- **macOS**: Homebrew (`brew install flux kubectl talosctl`)
- **Linux**: Package manager or direct downloads

**Required Tools**:

- `flux` - Flux CLI for GitOps operations
- `kubectl` - Kubernetes CLI
- `talosctl` - Talos Linux CLI
- `task` - Task runner (go-task)
- `sops` - Secret encryption
- `minijinja-cli` - Template rendering
- `kubeconform` - Manifest validation
- `stern` - Multi-pod log tailing
- `pre-commit` - Git hook framework
- `direnv` - Environment variable management

**Version Checking**:

```bash
flux version
kubectl version --client
talosctl version --client
task --version
sops --version
```

---

## Cluster Context Switching

### Kubectl Context Management

```bash
# List available contexts
kubectl config get-contexts

# Switch context (main cluster)
kubectl config use-context main

# Switch context (staging cluster)
kubectl config use-context staging

# View current context
kubectl config current-context

# Use explicit context (recommended)
kubectl --context main get pods -A
kubectl --context staging get pods -A
```

**Pattern**: Always use `--context` flag rather than switching default context to avoid mistakes.

### Flux Context Management

```bash
# Flux always requires explicit context
flux get kustomizations --context main
flux get helmreleases -A --context staging

# No default context switching for Flux
```

### Talosctl Context Management

```bash
# Talosctl uses explicit talosconfig files
talosctl --talosconfig kubernetes/main/talosconfig health
talosctl --talosconfig kubernetes/staging/talosconfig health

# No context switching needed
```

---

## Evidence

| Claim                                      | Source                                                          | Confidence |
| ------------------------------------------ | --------------------------------------------------------------- | ---------- |
| GitHub MCP server configured               | `.mcp.json`                                                     | Verified   |
| Mermaid MCP server configured              | `.mcp.json`                                                     | Verified   |
| Taskfile commands available                | `Taskfile.yaml`, `.taskfiles/`                                  | Verified   |
| Flux tasks require cluster parameter       | `.taskfiles/Flux/Taskfile.yaml`                                 | Verified   |
| Kubernetes tasks require cluster parameter | `.taskfiles/Kubernetes/Taskfile.yaml`                           | Verified   |
| Two independent clusters exist             | `kubernetes/main/`, `kubernetes/staging/`                       | Verified   |
| Kubeconfig per cluster                     | `kubernetes/main/kubeconfig`, `kubernetes/staging/kubeconfig`   | Verified   |
| Talosconfig per cluster                    | `kubernetes/main/talosconfig`, `kubernetes/staging/talosconfig` | Verified   |
| Direnv configuration exists                | `.envrc`                                                        | Verified   |
| Pre-commit hooks configured                | `.pre-commit-config.yaml`                                       | Verified   |
| Kubeconform validation script              | `scripts/kubeconform.sh`                                        | Verified   |
| SOPS encryption required for secrets       | `.taskfiles/Sops/Taskfile.yaml`, pre-commit hooks               | Verified   |
| Volsync for backup/restore                 | `.taskfiles/Volsync/Taskfile.yaml`                              | Verified   |
| CloudNativePG database operations          | `.taskfiles/Postgres/Taskfile.yaml`                             | Verified   |

---

## Non-Obvious Truths

- **Always specify cluster context**: Nearly every operation needs `--context main` or `--context staging`
- **Kubeconfig location matters**: Each cluster has its own kubeconfig in `kubernetes/<cluster>/kubeconfig`
- **Taskfile cluster parameter**: Most tasks require `cluster=<main|staging>` parameter
- **Main vs Staging differences**: Main runs on physical hardware, staging on Proxmox VMs
- **SOPS files must be encrypted**: Pre-commit hook prevents unencrypted `*.sops.yaml` files
- **Template rendering is cluster-agnostic**: `task configure` renders both clusters simultaneously
- **Direnv loads secrets**: `.envrc` decrypts `config.sops.env` for environment variables
- **Volsync requires specific naming**: App, HelmRelease, PVC, and ReplicationSource must share the same name
- **Postgres operations target main**: Database tasks primarily work with main cluster
- **Pre-commit runs automatically**: After `task pre-commit:init`, hooks run on every commit

---

## Related Documentation

- @docs/ai-context/ARCHITECTURE.md - System architecture and component relationships
- @docs/ai-context/WORKFLOWS.md - Deployment, update, and troubleshooting workflows
- @docs/ai-context/CONVENTIONS.md - Naming, structure, and style conventions
- @docs/ai-context/mermaid-diagram-guide.md - Diagram standards and validation
- @.claude/CLAUDE.md - Quick reference and critical invariants

---
description: Coding standards, naming conventions, and project structure rules for dual-cluster k8s-homelab
tags: ["NamingConventions", "DirectoryStructure", "CommitGuidelines", "YAMLStyle", "Jinja2Templates"]
audience: ["LLMs", "Humans"]
categories: ["Conventions[100%]", "Reference[85%]"]
---

# Repository Conventions

## Critical Context

This repository manages **TWO independent clusters**: main and staging. Always specify which cluster when documenting or making changes.

---

## Directory Structure

### Capsule: DualClusterDirectories

**Invariant**
Main cluster code lives in `kubernetes/main/`; staging cluster code lives in `kubernetes/staging/`; they never share code.

**Example**

```
kubernetes/
├── main/           # Production cluster on physical hardware
│   ├── apps/
│   ├── bootstrap/
│   ├── cluster/
│   ├── components/
│   └── talos/
└── staging/        # Testing cluster on Proxmox
    ├── apps/
    ├── bootstrap/
    ├── cluster/
    ├── components/
    └── talos/
```

//BOUNDARY: Changes to `kubernetes/main/` never affect `kubernetes/staging/` and vice versa.

**Depth**

- Distinction: Not environments or branches - completely separate infrastructures
- Trade-off: Duplicate configuration ensures production isolation vs shared code for consistency
- NotThis: They don't share namespaces, apps, secrets, or Flux state
- SeeAlso: `DualClusterIsolation` in ARCHITECTURE.md

---

### Template vs Generated

| Location                                         | Type             | Edit?        | Purpose                   |
| ------------------------------------------------ | ---------------- | ------------ | ------------------------- |
| `kubernetes/{main,staging}/talos/**/*.j2`        | Jinja2 templates | Yes - source | Node configurations       |
| `kubernetes/{main,staging}/bootstrap/templates/` | Jinja2 templates | Yes - source | Bootstrap manifests       |
| `kubernetes/{main,staging}/apps/`                | Static YAML      | Yes          | Application manifests     |
| `kubernetes/{main,staging}/cluster/`             | Static YAML      | Yes          | Flux configuration        |
| `.minijinja.toml`                                | Config           | Yes          | Template rendering config |

**Critical**: The k8s-homelab project uses Jinja2 for **Talos node configs and bootstrap only**, not for all manifests like some repos.

---

### App Structure Pattern

### Capsule: InstallYamlPattern

**Invariant**
Each app has `install.yaml` (Flux Kustomization wrapper) pointing to subdirectories with actual resources.

**Example**

```
kubernetes/main/apps/<namespace>/<app>/
├── install.yaml                    # Flux Kustomization (entry point)
├── app/                            # Application resources
│   ├── helmrelease.yaml           # HelmRelease
│   ├── kustomization.yaml         # Kustomize resources list
│   ├── secrets.yaml               # ExternalSecret (optional)
│   └── *-pvc.yaml                 # PVCs (optional)
└── db/                             # Database resources (optional)
    ├── helmrelease.yaml
    ├── kustomization.yaml
    ├── secrets.yaml
    └── cluster.yaml               # CloudNativePG cluster
```

**Depth**

- Distinction: install.yaml is Flux entry point; subdirectories contain actual resources
- Components: install.yaml can reference shared components from `kubernetes/{main,staging}/components/`
- Variables: install.yaml uses `postBuild.substitute` for templating
- Dependencies: install.yaml declares `dependsOn` for deployment order
- NotThis: Putting HelmRelease directly in namespace folder
- SeeAlso: `AppTemplateChart`, `ExternalSecretSync`

**Evidence**

| Claim | Source | Confidence |
|-------|--------|------------|
| install.yaml pattern used | `kubernetes/main/apps/media/immich/install.yaml` | Verified |
| Subdirectory organization | `kubernetes/main/apps/media/immich/app/` and `.../db/` | Verified |

---

### Namespace Organization

| Namespace               | Purpose              | Key Apps                                       |
| ----------------------- | -------------------- | ---------------------------------------------- |
| `actions-runner-system` | GitHub Actions       | actions-runner-controller                      |
| `cert-manager`          | TLS certificates     | cert-manager                                   |
| `dbms`                  | Databases            | cloudnative-pg, dragonfly, pgadmin4            |
| `default`               | Test apps            | whoami                                         |
| `external-secrets`      | Secret sync          | external-secrets, onepassword-connect          |
| `flux-system`           | GitOps               | Flux controllers, sources, alerts              |
| `home`                  | Home utilities       | home-assistant                                 |
| `jobs`                  | Batch jobs           | CronJobs for maintenance                       |
| `kube-system`           | Core Kubernetes      | cilium, coredns, metrics-server                |
| `media`                 | Media management     | plex, immich, \*arr apps (14+ apps)            |
| `network`               | Networking           | envoy-gateway, external-dns, cloudflare-tunnel |
| `observability`         | Monitoring           | prometheus, grafana, loki, alloy               |
| `rook-ceph`             | Distributed storage  | rook-ceph-cluster, operators                   |
| `self-hosted`           | Self-hosted services | homepage, wikijs, pdf-tools                    |
| `system`                | System tools         | keda, kopia, volsync, reloader, spegel         |
| `system-upgrade`        | OS updates           | system-upgrade-controller                      |

---

## Naming Conventions

### Files

| Type               | Pattern              | Example                                                    |
| ------------------ | -------------------- | ---------------------------------------------------------- |
| Flux Kustomization | `install.yaml`       | `kubernetes/main/apps/media/immich/install.yaml`           |
| HelmRelease        | `helmrelease.yaml`   | `kubernetes/main/apps/media/immich/app/helmrelease.yaml`   |
| Kustomization      | `kustomization.yaml` | `kubernetes/main/apps/media/immich/app/kustomization.yaml` |
| ExternalSecret     | `secrets.yaml`       | `kubernetes/main/apps/media/immich/app/secrets.yaml`       |
| PVC                | `<name>-pvc.yaml`    | `kubernetes/main/apps/media/immich/app/immich-pvc.yaml`    |
| Jinja2 template    | `*.yaml.j2`          | `kubernetes/main/talos/nodes/k8s-1.yaml.j2`                |
| Component          | `components/<name>/` | `kubernetes/main/components/volsync/`                      |

### Resources

| Type           | Pattern                             | Example                            |
| -------------- | ----------------------------------- | ---------------------------------- |
| App name       | lowercase, hyphenated               | `home-assistant`, `pdf-tools`      |
| Secret name    | `<app>-secret`                      | `immich-secret`                    |
| PVC name       | `<app>-<purpose>`                   | `immich-data`, `immich-backups`    |
| ConfigMap      | `<app>-config` or `<app>-configmap` | `immich-configmap`                 |
| ExternalSecret | Same as target secret               | `immich` (creates `immich-secret`) |

---

## YAML Style

### HelmRelease Pattern

### Capsule: AppTemplateStandard

**Invariant**
Apps use `bjw-s/app-template` chart; vendor charts are exceptions requiring justification.

**Example**

```yaml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/bjw-s-labs/helm-charts/main/charts/other/app-template/schemas/helmrelease-helm-v2.schema.json
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: &app immich # Anchor for reuse
spec:
  interval: 1h
  chartRef:
    kind: OCIRepository
    name: app-template
  maxHistory: 3
  install:
    createNamespace: true
    remediation:
      retries: 3
  upgrade:
    cleanupOnFail: true
    remediation:
      retries: 3
  uninstall:
    keepHistory: false
  values:
    controllers:
      server:
        strategy: Recreate
        annotations:
          secret.reloader.stakater.com/reload: immich-secret
        containers:
          main:
            image:
              repository: ghcr.io/immich-app/immich-server
              tag: v2.4.1@sha256:e6a6298e67ae077808fdb7d8d5565955f60b0708191576143fc02d30ab1389d1
            envFrom:
              - secretRef:
                  name: immich-secret
```

**Depth**

- Schema: Always include yaml-language-server schema comment
- Interval: Standard is `1h` (hourly reconciliation)
- ChartRef: Use OCIRepository named `app-template` in `flux-system` namespace
- Retries: Always set remediation retries (typically 3)
- Anchors: Use YAML anchors (`&app`, `*app`) for repeated values
- NotThis: Random Helm charts without checking if app-template works
- SeeAlso: `ImagePinning`, `ExternalSecretSync`

---

### Image Tags

### Capsule: ImageDigestPinning

**Invariant**
Production images must include `@sha256:` digest; Renovate updates both tag and digest automatically.

**Example**

```yaml
# CORRECT
image:
  repository: ghcr.io/immich-app/immich-server
  tag: v2.4.1@sha256:e6a6298e67ae077808fdb7d8d5565955f60b0708191576143fc02d30ab1389d1

# WRONG
tag: latest                          # Never use
tag: v2.4.1                          # Missing digest
tag: v2.4.1@sha256:abc123            # Truncated digest
```

**Depth**

- Distinction: Tag alone can change; digest is immutable and guarantees exact image
- Automation: Renovate updates both tag and digest in PRs
- Trade-off: Extra verbosity but guarantees reproducibility
- NotThis: Using `:latest` or tags without digests in production
- SeeAlso: `RenovateAutomation` in ARCHITECTURE.md

**Evidence**

| Claim | Source | Confidence |
|-------|--------|------------|
| Images pinned with digest | `kubernetes/main/apps/media/immich/app/helmrelease.yaml:51` | Verified |
| Renovate updates digests | `.renovaterc.json5`, automated PRs | Verified |

---

### Environment Variables

```yaml
# From ExternalSecret
envFrom:
  - secretRef:
      name: app-secret

# Direct values (avoid for secrets)
env:
  TZ: America/Los_Angeles # Use actual value, not ${TIMEZONE}
  LOG_LEVEL: info
# Composed in ExternalSecret template
# See secrets.yaml for DB_URL construction
```

**Critical**: Unlike some repos, k8s-homelab doesn't use `${VARIABLE}` substitution in HelmReleases. Values come from ExternalSecrets or are hardcoded.

---

### Storage Configuration

```yaml
# Rook/Ceph block storage (fast, replicated)
persistence:
  config:
    enabled: true
    storageClass: rook-ceph-block
    accessMode: ReadWriteOnce
    size: 10Gi
    globalMounts:
      - path: /config

# NFS storage (large capacity)
persistence:
  media:
    enabled: true
    type: nfs
    server: synology.internal.${SECRET_DOMAIN}
    path: /volume1/media
    globalMounts:
      - path: /media
        readOnly: true

# Tmpfs (ephemeral)
persistence:
  cache:
    enabled: true
    type: emptyDir
    medium: Memory
    globalMounts:
      - path: /cache
```

---

## Jinja2 Template Conventions

### Capsule: Jinja2Delimiters

**Invariant**
Jinja2 templates use standard `{{ }}` delimiters; `.minijinja.toml` configures rendering behavior.

**Example**

```yaml
# In kubernetes/main/talos/nodes/k8s-1.yaml.j2
machine:
  network:
    hostname: { { env("HOSTNAME") } }
    interfaces:
      - hardwareAddr: { { env("MAC_ADDRESS") } }
```

//BOUNDARY: Jinja2 used only for Talos configs and bootstrap templates, not app manifests.

**Depth**

- Distinction: Uses standard `{{ }}` not `#{ }#` like some repos
- Context: Variables come from environment (`.minijinja.toml` has `env = true`)
- Scope: Only used for Talos node configs and bootstrap manifests
- Rendering: Local rendering before commit (not server-side)
- NotThis: Not used for HelmRelease manifests (those use native Helm templating)
- SeeAlso: `MakejinjaTemplates` equivalent pattern

**Evidence**

| Claim | Source | Confidence |
|-------|--------|------------|
| Standard Jinja2 delimiters | `kubernetes/main/talos/nodes/k8s-1.yaml.j2` | Verified |
| Environment variable access | `.minijinja.toml:5` (env = true) | Verified |
| Limited scope usage | Only `.j2` files in `talos/` and `bootstrap/` | Verified |

---

### Template Variables

**Environment variables** (accessed via `env("VAR")`):

- Set in shell before rendering
- Used for node-specific values (hostname, MAC address, disk)
- Not committed to repository

**No central config.yaml** in k8s-homelab (unlike some other repos).

---

## Git Conventions

### Commit Messages

### Capsule: CommitMessageFormat

**Invariant**
Commit messages follow conventional commits: `type(scope): description`.

**Example**

```
chore(immich): Rework configuration
fix(pdf-tools): Add a real config volume
chore(envoy-gateway): Use trustedcidrs in client traffic policy
```

**Depth**

| Type | Use For |
|------|---------|
| `feat` | New app or feature |
| `fix` | Bug fix (app or container update) |
| `chore` | Maintenance, configuration changes |
| `docs` | Documentation |
| `refactor` | Code restructure |

**Scope**: Usually the app name or component name.

**Closing**: For AI-assisted commits, use:

```
Pair-programmed with Claude Code - https://claude.com/claude-code

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Gavin <gavin@nerdz.cloud>
```

**Evidence**

| Claim | Source | Confidence |
|-------|--------|------------|
| Conventional commits used | `git log --oneline -10` | Verified |
| AI pair-programming footer | `.claude/CLAUDE.md:122-127` | Verified |

---

### Branch Strategy

- `main` is the deployment branch for both clusters
- Flux reconciles from `main` (separate paths per cluster)
- Feature branches for complex changes
- Direct commits to `main` for simple changes acceptable

---

## Security Practices

### Secrets

### Capsule: ExternalSecretsOnly

**Invariant**
Secrets come from 1Password via ExternalSecrets; never commit unencrypted secrets.

**Example**

```yaml
# secrets.yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: immich
spec:
  refreshInterval: 12h
  secretStoreRef:
    kind: ClusterSecretStore
    name: onepassword-connect
  target:
    name: immich-secret
    creationPolicy: Owner
    template:
      data:
        DB_URL: "postgres://{{ .DB_USERNAME }}:{{ .DB_PASSWORD }}@immich-rw.media.svc.cluster.local:5432/immich"
  dataFrom:
    - extract:
        key: immich
```

//BOUNDARY: Missing 1Password entry blocks ExternalSecret sync, blocks pod startup.

**Depth**

- Distinction: 1Password is source of truth; ExternalSecrets sync to Kubernetes secrets
- Store: Always use ClusterSecretStore named `onepassword-connect`
- Template: Use template section to compose values from 1Password fields
- Refresh: Default 12h refresh interval
- Trade-off: More indirection but repo stays public safely
- NotThis: SOPS encryption (used in some repos but not primary here)
- SeeAlso: `ExternalSecretSync` in ARCHITECTURE.md

---

### File Permissions

```bash
# Sensitive files (if present locally)
chmod 600 ~/.kube/config-homelab
chmod 600 ~/1password-credentials.json
```

### .gitignore

Already configured to exclude:

- `.env`
- `*.key`
- `kubeconfig*`
- `.venv/`
- Sensitive credentials

---

## Routing Conventions

### Gateway References

### Capsule: EnvoyGatewayNames

**Invariant**
Gateways are `envoy-internal` and `envoy-external` in namespace `network`.

**Example**

```yaml
# Internal app route
route:
  main:
    parentRefs:
      - name: envoy-internal
        namespace: network
        sectionName: https
    hostnames:
      - "{{ .Release.Name }}.${SECRET_DOMAIN}"

# External app route
route:
  main:
    parentRefs:
      - name: envoy-external
        namespace: network
        sectionName: https
    hostnames:
      - "{{ .Release.Name }}.${SECRET_DOMAIN}"
```

**Depth**

| Gateway | Name | Namespace | Purpose |
|---------|------|-----------|---------|
| Internal | `envoy-internal` | `network` | Private network access |
| External | `envoy-external` | `network` | Public internet access |

**Common mistakes**:

- ❌ Using `internal` or `external` (wrong - need `envoy-` prefix)
- ❌ Wrong namespace (must be `network`)
- ❌ Wrong section name (must be `https`, not `http`)

**Evidence**

| Claim | Source | Confidence |
|-------|--------|------------|
| Gateway names | `kubernetes/main/apps/network/envoy-gateway/` | Verified |
| Section name is https | Gateway API configuration | Verified |

---

### DNS Annotations

**External-DNS** watches HTTPRoutes and creates DNS records automatically based on hostnames and annotations.

```yaml
# No special annotation needed for basic routes
# external-dns discovers routes automatically
route:
  main:
    hostnames:
      - photos.${SECRET_DOMAIN}
```

---

## Validation

### Before Commit

1. **Render templates** (if editing `.j2` files):

   ```bash
   # Render Talos configs or bootstrap templates
   minijinja-cli kubernetes/main/talos/nodes/k8s-1.yaml.j2 > output.yaml
   ```

2. **Validate manifests**:

   ```bash
   task kubernetes:kubeconform cluster=main
   # or
   task kubernetes:kubeconform cluster=staging
   ```

3. **Review changes**:

   ```bash
   git diff kubernetes/main/apps/
   ```

### After Push

1. Check Flux reconciliation:

   ```bash
   flux get kustomizations -A --context main
   flux get helmreleases -A --context main
   # or
   flux get kustomizations -A --context staging
   flux get helmreleases -A --context staging
   ```

2. Check pods:

   ```bash
   kubectl get pods -A --context main
   # or
   kubectl get pods -A --context staging
   ```

3. Check ExternalSecrets:

   ```bash
   kubectl get externalsecrets -A --context main
   # or
   kubectl get externalsecrets -A --context staging
   ```

---

## Common Patterns & Mistakes

### Storage Classes

**Invariant**: Storage classes are `rook-ceph-block` and `rook-ceph-filesystem`.

```yaml
# CORRECT
storageClassName: rook-ceph-block       # Single-instance apps, databases
storageClassName: rook-ceph-filesystem  # Shared/multi-instance

# WRONG
storageClassName: ceph-block-storage    # Does not exist
storageClassName: cephfs                # Wrong name
```

---

### ExternalSecret Provider

**Invariant**: ClusterSecretStore name is `onepassword-connect`.

```yaml
# CORRECT
secretStoreRef:
  kind: ClusterSecretStore
  name: onepassword-connect

# WRONG
name: onepassword         # Missing "-connect"
name: 1password-connect   # Wrong prefix
```

---

### Route Hostnames

**Invariant**: Use Helm template for hostname when using app-template chart.

```yaml
# CORRECT
hostnames:
  - "{{ .Release.Name }}.${SECRET_DOMAIN}"

# ACCEPTABLE (if Release name differs from desired hostname)
hostnames:
  - photos.${SECRET_DOMAIN}

# WRONG - Creates drift if app renamed
hostnames:
  - immich.${SECRET_DOMAIN}  # When .Release.Name is "immich"
```

---

### Security Context

**Standard UID/GID**: Many apps use `2000` (immich) or `568` (common default). Check app documentation.

```yaml
# Common pattern
pod:
  securityContext:
    runAsNonRoot: true
    runAsUser: 2000
    runAsGroup: 2000
    fsGroup: 2000
    fsGroupChangePolicy: OnRootMismatch

# Container-level
containers:
  main:
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true # When supported by app
      capabilities:
        drop: ["ALL"]
```

---

### Probes

**Invariant**: Check actual app documentation for probe endpoints; don't assume.

| App Type                  | Common Probe Path       |
| ------------------------- | ----------------------- |
| Arr apps (Radarr, Sonarr) | `/ping`                 |
| Immich                    | `/api/server-info/ping` |
| Generic web apps          | `/` or `/health`        |

```yaml
# CORRECT - Verify path for specific app
probes:
  liveness:
    enabled: true
    spec:
      httpGet:
        path: /ping # Verified for this app
        port: &port 8080
      initialDelaySeconds: 30
      periodSeconds: 10
```

---

### Reloader Annotations

**Pattern**: Use reloader to restart pods when secrets/configmaps change.

```yaml
controllers:
  server:
    annotations:
      secret.reloader.stakater.com/reload: immich-secret
      configmap.reloader.stakater.com/reload: immich-configmap
```

---

## Components (Shared Kustomize Resources)

### Capsule: SharedComponents

**Invariant**
Reusable Kustomize components live in `kubernetes/{main,staging}/components/` and are referenced in install.yaml.

**Example**

```yaml
# In install.yaml
components:
  - ../../../../components/gatus/guarded
  - ../../../../components/nfs-scaler
```

**Available Components**:

- `components/alerts/` - Alert configurations
- `components/app-template/` - App template OCI repository
- `components/gatus/` - Healthcheck monitoring
- `components/volsync/` - Backup replication
- `components/nfs-scaler/` - NFS-based autoscaling

**Depth**

- Distinction: Components are reusable across apps; not copied per-app
- Usage: Referenced via relative path in Kustomization components field
- Cluster-specific: Each cluster has its own components (no sharing between main/staging)
- SeeAlso: Kustomize components documentation

---

## Dependencies

### Capsule: FluxDependencies

**Invariant**
install.yaml declares dependencies via `dependsOn` to ensure deployment order.

**Example**

```yaml
# In kubernetes/main/apps/media/immich/install.yaml
spec:
  dependsOn:
    - name: immich-database
      namespace: media
    - name: keda
      namespace: system
    - name: external-secrets
      namespace: external-secrets
```

**Depth**

- Common dependencies:
  - `external-secrets` - Required if app uses ExternalSecrets
  - `cloudnative-pg-operator` - Required for PostgreSQL databases
  - `rook-ceph-cluster` - Required if using Ceph storage
  - `envoy-gateway` - Required if app has HTTPRoutes
- Flux waits for dependencies to be Ready before deploying app
- Cross-namespace dependencies allowed
- SeeAlso: `GitOpsReconciliation` in ARCHITECTURE.md

---

## Documentation Standards

### Cluster Context

**Hard Rule**: Always specify which cluster (main or staging) when documenting.

```markdown
✅ CORRECT:
Home Assistant runs in the `home` namespace on the main cluster.

❌ WRONG:
Home Assistant runs in the `home` namespace.
```

### File Path Format

**Always use absolute paths** in documentation:

```markdown
✅ CORRECT:
See kubernetes/main/apps/media/immich/app/helmrelease.yaml:51

❌ WRONG:
See helmrelease.yaml
See ../immich/app/helmrelease.yaml
```

### Placeholder Usage

**Never expose actual values** (see Ethos.md Rule 3):

```markdown
✅ CORRECT:
https://photos.${SECRET_DOMAIN}
op://Private/immich/password

❌ WRONG:
https://photos.example.com
op://Private/immich/mySecretPassword123
```

---

## Evidence

| Claim                          | Source                                                           | Confidence |
| ------------------------------ | ---------------------------------------------------------------- | ---------- |
| Two independent clusters       | `kubernetes/main/` and `kubernetes/staging/` directories         | Verified   |
| install.yaml pattern           | `kubernetes/main/apps/media/immich/install.yaml`                 | Verified   |
| ExternalSecrets with 1Password | `kubernetes/main/apps/external-secrets/`, app secrets.yaml files | Verified   |
| onepassword-connect store      | `kubernetes/main/apps/media/immich/app/secrets.yaml:11`          | Verified   |
| Envoy Gateway routing          | `kubernetes/main/apps/network/envoy-gateway/`                    | Verified   |
| Gateway names                  | envoy-internal, envoy-external in network namespace              | Verified   |
| Jinja2 standard delimiters     | `kubernetes/main/talos/nodes/*.j2` files                         | Verified   |
| Image digest pinning           | SHA256 in helmrelease.yaml files                                 | Verified   |
| bjw-s/app-template standard    | HelmRelease chartRef across apps                                 | Verified   |
| Renovate automation            | `.renovaterc.json5`, automated update PRs                        | Verified   |
| Conventional commits           | `git log --oneline` output                                       | Verified   |
| Storage classes                | rook-ceph-block, rook-ceph-filesystem                            | Verified   |
| Components pattern             | `kubernetes/main/components/` directory structure                | Verified   |
| Flux dependencies              | dependsOn in install.yaml files                                  | Verified   |

---

## Quick Reference

| Task                      | Command                                                                         |
| ------------------------- | ------------------------------------------------------------------------------- |
| Validate manifests        | `task kubernetes:kubeconform cluster=main`                                      |
| Check Flux status         | `flux get helmreleases -A --context main`                                       |
| Force reconciliation      | `flux reconcile kustomization <name> -n flux-system --context main`             |
| Check ExternalSecrets     | `kubectl get externalsecrets -A --context main`                                 |
| View 1Password connection | `kubectl logs -n external-secrets deploy/onepassword-connect --context main`    |
| List apps in namespace    | `ls kubernetes/main/apps/<namespace>/`                                          |
| Find Jinja2 templates     | `find kubernetes/main -name "*.j2"`                                             |

---

**See Also**:

- `ARCHITECTURE.md` - System architecture and capsule patterns
- `WORKFLOWS.md` - How to deploy, update, troubleshoot
- `Ethos.md` - Documentation philosophy and hard rules
- `NETWORKING.md` - Traffic flows, DNS, gateways, OIDC

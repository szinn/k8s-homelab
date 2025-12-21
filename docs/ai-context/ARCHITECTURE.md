---
description: Dual-cluster GitOps architecture covering Flux reconciliation, template pipeline, routing patterns, and operational constraints
tags: ["GitOps", "FluxReconciliation", "Jinja2Templates", "EnvoyGateway", "DualCluster", "ExternalSecrets"]
audience: ["LLMs", "Humans"]
categories: ["Architecture[100%]", "Reference[90%]"]
---

# Dual-Cluster Homelab Architecture

## Core Pattern

### Capsule: DualClusterIsolation

**Invariant**
Main and staging clusters are independent; no shared code, separate configurations, isolated infrastructure.

**Example**
Main cluster lives in `kubernetes/main/`; staging cluster lives in `kubernetes/staging/`; changes to one never affect the other.
//BOUNDARY: No automatic sync between clusters; copying requires explicit manual action.

**Depth**

- Distinction: Not environments or branches - completely separate infrastructures
- Trade-off: Duplicate configuration for safety vs shared code for consistency
- NotThis: They don't share namespaces, apps, or Flux state
- Critical: Always specify which cluster when making changes
- SeeAlso: `ClusterOrganization`, `GitOpsReconciliation`

---

### Capsule: GitOpsReconciliation

**Invariant**
Cluster state converges to match Git; Flux reverts manual changes on next sync.

**Example**
Push HelmRelease to `kubernetes/main/apps/media/immich/app/helmrelease.yaml`; Flux detects within 1 hour; cluster deploys. `kubectl edit` gets overwritten on reconciliation.

**Depth**

- Distinction: GitOps is declarative (desired state in Git); `kubectl` is imperative
- Trade-off: Consistency and auditability vs immediate manual changes
- NotThis: `kubectl apply` bypasses GitOps and creates drift
- Timing: Flux reconciles every 1 hour or on Git push webhook
- SeeAlso: `Jinja2Templates`, `FluxBootstrap`

---

### Capsule: Jinja2Templates

**Invariant**
Jinja2 templates (`.j2` files) render to manifests locally before deploying. Rendered manifests should not be committed.

**Example**
Edit `kubernetes/main/talos/nodes/k8s-1.yaml.j2` -> render locally with Jinja2 -> rendered output and is deployed manually the main cluster.
//BOUNDARY: Committing unrendered `.j2` files does not break cluster reconciliation.

**Depth**

- Distinction: Templates use `#{variable}#` syntax (not `{{}}` to avoid Helm conflicts)
- Trade-off: Extra local step but enables dynamic configuration
- NotThis: Pushing `.j2` files directly to Git
- Tools: `.minijinja.toml` configures rendering
- SeeAlso: `GitOpsReconciliation`, `ExternalSecretSync`

---

### Capsule: ExternalSecretSync

**Invariant**
ExternalSecrets pull from 1Password; Kubernetes secrets populate before pods can start.

**Example**
HelmRelease references `app-secret`; ExternalSecret pulls from `op://Private/app/password`; pod receives value at runtime.
//BOUNDARY: Missing 1Password entry blocks ExternalSecret sync, blocking pod startup.

**Depth**

- Distinction: 1Password is source of truth; ExternalSecrets sync values to cluster
- Trade-off: More indirection, but repo stays public safely and secrets centralized
- NotThis: Hardcoding secrets in manifests defeats the pattern
- Store: ClusterSecretStore named `onepassword-connect`
- Refresh: ExternalSecrets refresh every 12 hours by default
- SeeAlso: `OnePasswordIntegration`, `SecretManagement`

---

## Routing Patterns

### Capsule: EnvoyGatewayRouting

**Invariant**
External/internal traffic routes via Envoy Gateway using Gateway API `HTTPRoute`.

**Example**

```yaml
route:
  internal-app:
    hostnames:
      - home.${SECRET_DOMAIN}
    parentRefs:
      - name: envoy-internal
        namespace: network
```

//BOUNDARY: Missing `parentRefs` or wrong gateway name breaks routing entirely.

**Depth**

- Distinction: `envoy-external` gateway for public internet; `envoy-internal` gateway for private network
- Gateway names: `envoy-external`, `envoy-internal` (both in `network` namespace)
- Trade-off: More explicit than Ingress but requires Gateway API infrastructure
- NotThis: Old-style Kubernetes Ingress resources (Gateway API is the standard)
- SeeAlso: `ExternalDNS`, `ClientTrafficPolicy`

---

### Capsule: ExternalDNS

**Invariant**
external-dns watches HTTPRoutes and creates Cloudflare DNS records automatically.

**Example**
HTTPRoute with hostname `app.${SECRET_DOMAIN}` -> external-dns creates A/CNAME record pointing to gateway -> traffic flows.

**Depth**

- Distinction: DNS records managed declaratively from cluster, not manually in Cloudflare
- Trade-off: Automation vs manual control
- Provider: Cloudflare (configured in `kubernetes/{main,staging}/apps/network/external-dns/`)
- SeeAlso: `EnvoyGatewayRouting`

---

## Application Patterns

### Capsule: AppTemplateChart

**Invariant**
Apps use `bjw-s/app-template` chart; vendor charts are exceptions, not defaults.

**Example**

```yaml
chart:
  spec:
    chart: app-template
    version: 3.x.x
    sourceRef:
      kind: HelmRepository
      name: bjw-s
      namespace: flux-system
```

**Depth**

- Distinction: app-template provides consistent structure; vendor charts vary wildly
- Trade-off: Learning curve but consistent patterns across all apps
- NotThis: Using random Helm charts without checking if app-template works
- Schema validation: Apps include JSON schema for validation
- SeeAlso: `HelmReleaseStructure`, `InstallYamlPattern`

---

### Capsule: InstallYamlPattern

**Invariant**
Each app has `install.yaml` (Flux Kustomization wrapper) pointing to `app/` subdirectory with HelmRelease.

**Example**

```
kubernetes/main/apps/media/immich/
├── install.yaml          # Flux Kustomization (entry point)
└── app/
    ├── helmrelease.yaml  # HelmRelease definition
    ├── kustomization.yaml # Kustomize resources list
    └── secrets.yaml       # ExternalSecret (optional)
```

**Depth**

- Distinction: install.yaml is Flux entry; app/ contains actual resources
- Pattern: Consistent across all apps in both clusters
- Variables: install.yaml can use postBuild.substitute for templating
- NotThis: Putting HelmRelease directly in namespace folder
- SeeAlso: `AppTemplateChart`, `ExternalSecretSync`

---

### Capsule: ImagePinning

**Invariant**
Production images include `@sha256:` digest; Renovate updates digests automatically.

**Example**

```yaml
image:
  repository: ghcr.io/immich-app/immich-server
  tag: v1.118.0@sha256:abc123...
```

**Depth**

- Distinction: Tag alone can change; digest is immutable
- Trade-off: Extra verbosity but guarantees exact image version
- Automation: Renovate updates both tag and digest
- NotThis: Using `:latest` or tags without digests in production
- SeeAlso: `RenovateAutomation`

---

## Directory Structure

### Main Cluster

```
kubernetes/main/
├── apps/                  # 16 namespaces, 78+ HelmReleases
│   ├── cert-manager/
│   ├── dbms/              # CloudNative-PG, Dragonfly, pgAdmin
│   ├── default/
│   ├── external-secrets/
│   ├── flux-system/
│   ├── home/              # Home Assistant
│   ├── jobs/
│   ├── kube-system/       # Cilium, CoreDNS, metrics-server
│   ├── media/             # Plex, *arr apps, qBittorrent (14 apps)
│   ├── network/           # Envoy Gateway, external-dns, multus
│   ├── observability/     # Prometheus, Grafana, Loki
│   ├── rook-ceph/         # Distributed storage
│   ├── self-hosted/       # Homepage, WikiJS, PDF tools
│   ├── system/            # KEDA, kopia, volsync, descheduler
│   ├── system-upgrade/
│   └── actions-runner-system/
├── bootstrap/             # Helmfile-based bootstrap
│   ├── helmfile.d/
│   └── resources.yaml.j2
├── cluster/               # Flux cluster configuration
├── components/            # Shared kustomize components
│   ├── alerts/
│   ├── app-template/
│   ├── gatus/
│   ├── volsync/
│   └── nfs-scaler/
├── talos/                 # Talos OS configuration
│   ├── nodes/             # k8s-1 through k8s-6 (.j2 templates)
│   ├── machineconfig.yaml.j2
│   └── talosconfig.j2
└── .justfile             # Cluster-specific tasks
```

### Staging Cluster

```
kubernetes/staging/
├── apps/                  # Same structure as main
├── bootstrap/
├── cluster/
├── components/
├── talos/
└── .justfile
```

**Key Insight**: Each cluster is a complete, independent configuration. No shared code between `main/` and `staging/`.

---

## Namespaces (Main Cluster)

| Namespace             | Purpose              | Key Apps                                                        |
| --------------------- | -------------------- | --------------------------------------------------------------- |
| actions-runner-system | GitHub Actions       | actions-runner-controller                                       |
| cert-manager          | TLS certificates     | cert-manager                                                    |
| dbms                  | Databases            | cloudnative-pg, dragonfly, pgadmin4                             |
| default               | Test apps            | whoami                                                          |
| external-secrets      | Secret sync          | external-secrets, onepassword-connect                           |
| flux-system           | GitOps               | flux controllers, sources, alerts                               |
| home                  | Home apps            | home-assistant                                                  |
| jobs                  | Batch jobs           | CronJobs for maintenance                                        |
| kube-system           | Core Kubernetes      | cilium, coredns, metrics-server, node-feature-discovery         |
| media                 | Media management     | plex, sonarr, radarr, bazarr, immich, seerr, prowlarr (14 apps) |
| network               | Networking           | envoy-gateway, external-dns, cloudflare-tunnel, multus          |
| observability         | Monitoring           | prometheus, grafana, loki, alloy, victoria-logs                 |
| rook-ceph             | Distributed storage  | rook-ceph-cluster, operators                                    |
| self-hosted           | Self-hosted services | homepage, wikijs, shlink, pdf-tools, change-detection           |
| system                | System tools         | keda, kopia, volsync, descheduler, reloader, spegel             |
| system-upgrade        | OS updates           | system-upgrade-controller                                       |

---

## Cluster Comparison

| Aspect             | Main Cluster                      | Staging Cluster           |
| ------------------ | --------------------------------- | ------------------------- |
| **Infrastructure** | 6 Intel NUC nodes (Talos OS)      | 3-node Proxmox cluster    |
| **Network**        | 10.11.x.x (HOMELAB VLAN)          | 10.12.x.x (STAGING VLAN)  |
| **Purpose**        | Production workloads              | Testing and validation    |
| **Storage**        | Rook/Ceph (NVMe) + NFS (Synology) | Proxmox storage           |
| **Apps**           | ~78 HelmReleases                  | Subset for testing        |
| **Secrets**        | 1Password (production vault)      | 1Password (staging vault) |

---

## Operational Limits

| Resource               | Behavior                                       |
| ---------------------- | ---------------------------------------------- |
| Flux reconciliation    | Every 1 hour or on Git push                    |
| HelmRelease retry      | Retries with exponential backoff               |
| ExternalSecret refresh | Every 12 hours                                 |
| Image pull             | Cached by Spegel (distributed registry mirror) |

---

## Storage Patterns

### Capsule: RookCephFast

**Invariant**
Rook/Ceph provides fast replicated storage from NVMe drives across worker nodes.

**Example**

```yaml
persistence:
  data:
    enabled: true
    storageClass: rook-ceph-block
    size: 10Gi
```

**Depth**

- Use case: Databases, stateful apps requiring fast I/O
- Replication: 3x across worker nodes
- Performance: NVMe-backed
- Trade-off: Limited capacity vs speed and redundancy
- NotThis: Not for large media files (use NFS instead)
- SeeAlso: `NFSStorage`

---

### Capsule: NFSStorage

**Invariant**
NFS provides large slow storage from Synology NAS for media and bulk data.

**Example**

```yaml
persistence:
  media:
    enabled: true
    type: nfs
    server: synology.internal
    path: /volume1/media
```

**Depth**

- Use case: Media files, downloads, backups
- Capacity: Multi-TB available
- Performance: Slower than Ceph but massive capacity
- Trade-off: Capacity vs speed
- NotThis: Not for databases or apps requiring fast I/O
- SeeAlso: `RookCephFast`, `VolSyncBackup`

---

## Bootstrap Process

### Sequence

1. **Talos Installation**
   - Apply machineconfig.yaml.j2 (rendered) to nodes
   - Nodes join cluster, bootstrap etcd

2. **Flux Bootstrap** (via Helmfile)
   - Install CRDs (00-crds.yaml)
   - Install Flux operators
   - Install core apps (01-apps.yaml)

3. **Dependency Order**
   - Cilium (networking)
   - CoreDNS (cluster DNS)
   - Spegel (image mirroring)
   - Cert-Manager (certificates)
   - Flux (GitOps)

4. **App Deployment**
   - Flux watches `kubernetes/{main,staging}/apps/`
   - Reconciles HelmReleases
   - Creates resources in order

---

## Common Failures

### HelmRelease stuck Reconciling

**Cause**: Missing ExternalSecret, invalid values, or chart error
**Fix**: Check `flux logs`, ensure ExternalSecrets are Ready, validate values
**Debug**: `flux get helmreleases -A`, `kubectl describe hr -n <namespace> <name>`

### Pod stuck Pending

**Cause**: ExternalSecret not synced, PVC not bound, or node affinity
**Fix**: Check `flux get externalsecrets -n <namespace>`, verify PVC exists, check node labels
**Debug**: `kubectl describe pod -n <namespace> <pod>`

### HTTPRoute not working

**Cause**: Missing gateway, wrong `parentRefs`, or DNS not configured
**Fix**: Verify gateway exists (`kubectl get gateway -n network`), check external-dns logs
**Debug**: `kubectl describe httproute -n <namespace> <name>`

### ExternalSecret failing to sync

**Cause**: Missing 1Password entry, wrong path, or onepassword-connect not ready
**Fix**: Verify entry exists in 1Password, check path format (`op://Vault/Item/Field`)
**Debug**: `kubectl describe externalsecret -n <namespace> <name>`, check onepassword-connect logs

---

## Automation

### Capsule: RenovateAutomation

**Invariant**
Renovate automatically updates container images, Helm charts, and GitHub Actions; creates PRs for review.

**Example**
Renovate detects immich v1.118.0 → v1.118.1, updates image tag and SHA digest, creates PR with changelog.

**Depth**

- Scope: Docker images, Helm charts, GitHub Actions, Taskfile tools
- Configuration: `.renovaterc.json5` + 11 config files in `.renovate/`
- Grouping: Separate groups for apps, system, Kubernetes
- Auto-merge: Patch/minor updates auto-merge if tests pass
- Trade-off: Automation vs manual control
- SeeAlso: `ImagePinning`

---

## Evidence

| Claim                          | Source                                                        | Confidence |
| ------------------------------ | ------------------------------------------------------------- | ---------- |
| Two independent clusters       | `kubernetes/main/` and `kubernetes/staging/` exist separately | Verified   |
| Apps use bjw-s/app-template    | `kubernetes/main/apps/*/app/helmrelease.yaml` chart refs      | Verified   |
| Envoy Gateway routing          | `kubernetes/main/apps/network/envoy-gateway/`                 | Verified   |
| ExternalSecrets with 1Password | `kubernetes/main/apps/external-secrets/`                      | Verified   |
| Jinja2 templates               | `.minijinja.toml`, `*.j2` files in `talos/` and `bootstrap/`  | Verified   |
| Flux reconciles hourly         | `kubernetes/main/apps/*/install.yaml` interval settings       | Verified   |
| Image digest pinning           | SHA256 digests in helmrelease.yaml files                      | Verified   |
| Renovate automation            | `.renovaterc.json5`, `.renovate/` configs                     | Verified   |

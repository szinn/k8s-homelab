---
description: Operational workflows for dual-cluster deployment, troubleshooting, and maintenance
tags: ["AppDeployment", "SecretManagement", "Troubleshooting", "DualCluster", "TaskfileOperations"]
audience: ["LLMs", "Humans"]
categories: ["How-To[100%]", "Workflows[95%]"]
---

# Homelab Workflows

**Purpose**: Practical workflows for deploying apps, managing secrets, troubleshooting failures, and maintaining the dual-cluster infrastructure.

**Critical**: This repository manages TWO independent clusters. Commands must specify the target cluster:

- **kubectl commands**: Add `--context main` or `--context staging`
- **flux commands**: Add `--context main` or `--context staging`
- **task commands** (cluster operations): Add `cluster=main` or `cluster=staging`
- **Repository tasks** (sops, pre-commit): No cluster parameter needed

---

## Deploying a New App

### Prerequisites

- Determine target cluster (main or staging)
- Decide namespace placement (see ARCHITECTURE.md for namespace purposes)
- Identify dependencies (databases, secrets, storage)

### Directory Structure

Create app structure in `kubernetes/{cluster}/apps/{namespace}/{app}/`:

```
kubernetes/main/apps/media/myapp/
├── install.yaml          # Flux Kustomization (entry point)
└── app/
    ├── helmrelease.yaml  # HelmRelease definition
    ├── kustomization.yaml # Kustomize resources list
    └── secrets.yaml       # ExternalSecret (if needed)
```

### Steps

**1. Create HelmRelease** using app-template pattern:

```yaml
# kubernetes/main/apps/media/myapp/app/helmrelease.yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: &app myapp
spec:
  interval: 30m
  chart:
    spec:
      chart: app-template
      version: 3.6.0
      sourceRef:
        kind: HelmRepository
        name: bjw-s
        namespace: flux-system
  install:
    remediation:
      retries: 3
  upgrade:
    cleanupOnFail: true
    remediation:
      retries: 3
  values:
    controllers:
      myapp:
        containers:
          app:
            image:
              repository: ghcr.io/org/myapp
              tag: latest@sha256:abc123... # Always pin digest
            env:
              TZ: America/New_York
            envFrom:
              - secretRef:
                  name: myapp-secret # Reference ExternalSecret
    service:
      app:
        controller: myapp
        ports:
          http:
            port: 8080
    route:
      app:
        parentRefs:
          - name: envoy-external # or envoy-internal
            namespace: network
            sectionName: https
        hostnames:
          - &host "myapp.${SECRET_DOMAIN}"
        tls:
          - hosts:
              - *host
    persistence:
      config:
        enabled: true
        storageClass: rook-ceph-block
        size: 5Gi
```

**2. Create Kustomization**:

```yaml
# kubernetes/main/apps/media/myapp/app/kustomization.yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./helmrelease.yaml
  - ./secrets.yaml # If using ExternalSecrets
```

**3. Create ExternalSecret** (if needed):

```yaml
# kubernetes/main/apps/media/myapp/app/secrets.yaml
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: myapp-secret
spec:
  secretStoreRef:
    name: onepassword-connect
    kind: ClusterSecretStore
  target:
    name: myapp-secret
    template:
      engineVersion: v2
      data:
        API_KEY: "{{ .api_key }}"
  dataFrom:
    - extract:
        key: myapp # 1Password item name
```

**4. Create install.yaml** (Flux entry point):

```yaml
# kubernetes/main/apps/media/myapp/install.yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: myapp
spec:
  targetNamespace: media
  path: ./kubernetes/main/apps/media/myapp/app
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  dependsOn:
    - name: external-secrets
      namespace: external-secrets
  prune: true
  wait: false
  interval: 30m
  timeout: 5m
```

**5. Wire into namespace kustomization**:

```yaml
# kubernetes/main/apps/media/kustomization.yaml
resources:
  - ./myapp/install.yaml # Add this line
  - ./immich/install.yaml
  - ./plex/install.yaml
```

**6. Validate and deploy**:

```bash
# Validate manifests
task kubernetes:kubeconform cluster=main

# Commit and push
git add kubernetes/main/apps/media/myapp/
git commit -m "feat(myapp): initial deployment to main cluster"
git push

# Force immediate sync (optional)
task flux:sync cluster=main
```

### Common Deployment Patterns

**NFS Storage** (for large media files):

```yaml
persistence:
  media:
    enabled: true
    type: nfs
    server: synology.internal
    path: /volume1/media
    globalMounts:
      - path: /media
```

**Multiple Containers** (app + sidecar):

```yaml
controllers:
  myapp:
    containers:
      app:
        image:
          repository: ghcr.io/org/app
          tag: latest@sha256:abc123...
      metrics:
        image:
          repository: ghcr.io/org/metrics-exporter
          tag: v1.0.0@sha256:def456...
```

**Database Dependency**:

```yaml
# In install.yaml
dependsOn:
  - name: myapp-database
    namespace: media
  - name: cloudnative-pg-operator
    namespace: dbms
```

---

## Updating an Existing App

### Image Update

**Preferred**: Let Renovate handle this automatically via PR.

**Manual**:

1. Edit `kubernetes/{cluster}/apps/{namespace}/{app}/app/helmrelease.yaml`
2. Update `image.tag` and `@sha256:` digest
3. Validate, commit, push

```bash
task kubernetes:kubeconform cluster=main
git add -A && git commit -m "chore(myapp): update to v1.2.3"
git push
```

### Configuration Update

Edit HelmRelease values section, then:

```bash
task kubernetes:kubeconform cluster=main
git add -A && git commit -m "feat(myapp): add new environment variable"
git push

# Force immediate reconciliation
task flux:hr-sync cluster=main
```

### Force Reconciliation

```bash
# Sync all resources
task flux:sync cluster=main

# Sync specific HelmRelease
flux reconcile hr myapp -n media --context main --with-source

# Force full reset (reinstall)
flux reconcile hr myapp -n media --context main --force --reset
```

---

## Adding Secrets via ExternalSecrets/1Password

### Workflow

**1. Add secret to 1Password**

- Create item in appropriate vault (main or staging)
- Use descriptive item name (matches app name)
- Add fields for each secret value

**2. Create ExternalSecret manifest**

```yaml
# kubernetes/main/apps/media/myapp/app/secrets.yaml
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: myapp-secret
spec:
  refreshInterval: 12h
  secretStoreRef:
    name: onepassword-connect
    kind: ClusterSecretStore
  target:
    name: myapp-secret
    template:
      engineVersion: v2
      data:
        # Map 1Password fields to secret keys
        DB_PASSWORD: "{{ .db_password }}"
        API_KEY: "{{ .api_key }}"
  dataFrom:
    - extract:
        key: myapp # 1Password item name
```

**3. Reference in HelmRelease**

```yaml
# In helmrelease.yaml
envFrom:
  - secretRef:
      name: myapp-secret
```

**4. Add to kustomization.yaml**

```yaml
# kubernetes/main/apps/media/myapp/app/kustomization.yaml
resources:
  - ./helmrelease.yaml
  - ./secrets.yaml # Add this
```

**5. Deploy**

```bash
task kubernetes:kubeconform cluster=main
git add -A && git commit -m "feat(myapp): add ExternalSecret for credentials"
git push
```

### SOPS-Encrypted Secrets (Alternative)

For secrets not in 1Password:

**1. Create secret file**:

```yaml
# kubernetes/main/apps/media/myapp/app/secret.sops.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secret
stringData:
  API_KEY: "actual-secret-value"
```

**2. Encrypt**:

```bash
sops --encrypt --in-place kubernetes/main/apps/media/myapp/app/secret.sops.yaml
```

**3. Re-encrypt all secrets** (after key rotation):

```bash
task sops:re-encrypt
```

---

## Troubleshooting HelmRelease Failures

### Check HelmRelease Status

```bash
# All HelmReleases across all namespaces
flux get helmreleases -A --context main

# Specific HelmRelease
flux get helmrelease myapp -n media --context main

# Detailed events
kubectl describe hr myapp -n media --context main
```

### Common Failure Modes

| Symptom                       | Cause                              | Fix                                                                      |
| ----------------------------- | ---------------------------------- | ------------------------------------------------------------------------ |
| **Install Retries Exhausted** | Missing dependency, invalid values | Check controller logs (see View Logs section), verify dependencies exist |
| **Upgrade Failed**            | Chart compatibility issue          | Review chart version, check breaking changes                             |
| **Reconciliation Suspended**  | Manual suspension                  | `flux resume hr myapp -n media --context main`                           |
| **Secret not found**          | ExternalSecret not synced          | Check `kubectl get es -n media --context main`                           |
| **Image pull error**          | Invalid digest, registry auth      | Verify image exists, check imagePullSecrets                              |

### View Logs

```bash
# Helm controller logs
kubectl logs -n flux-system deploy/helm-controller --context main --tail=100

# Kustomize controller logs
kubectl logs -n flux-system deploy/kustomize-controller --context main --tail=100

# Source controller logs
kubectl logs -n flux-system deploy/source-controller --context main --tail=100

# App pod logs
kubectl logs -n media -l app.kubernetes.io/name=myapp --context main
```

### Force HelmRelease Reconciliation

```bash
# Single HelmRelease
flux reconcile hr myapp -n media --context main --with-source

# All HelmReleases
task flux:hr-sync cluster=main

# Force reset (reinstall)
task flux:force-hr-sync cluster=main
```

### Suspend/Resume HelmReleases

```bash
# Suspend (stops reconciliation)
flux suspend hr myapp -n media --context main

# Resume
flux resume hr myapp -n media --context main

# Suspend all
task flux:hr-suspend cluster=main

# Resume all
task flux:hr-resume cluster=main
```

---

## Checking Flux Reconciliation Status

### Overall Cluster Health

```bash
# All Flux resources
flux stats --context main

# Kustomizations
flux get kustomizations --context main

# GitRepositories
flux get sources git --context main

# HelmRepositories
flux get sources helm --context main

# HelmReleases
flux get helmreleases -A --context main
```

### Reconciliation Times

```bash
# Show last reconciliation times
flux get kustomizations --context main -o wide

# Watch reconciliation progress
flux get kustomizations --context main --watch
```

### Check for Suspended Resources

```bash
# Suspended Kustomizations
kubectl get kustomizations -A --context main -o json | \
  jq -r '.items[] | select(.spec.suspend==true) | "\(.metadata.namespace)/\(.metadata.name)"'

# Suspended HelmReleases
kubectl get hr -A --context main -o json | \
  jq -r '.items[] | select(.spec.suspend==true) | "\(.metadata.namespace)/\(.metadata.name)"'
```

---

## Forcing a Flux Sync

### Full Cluster Sync

```bash
# Sync GitRepository and cluster-apps Kustomization
task flux:sync cluster=main
```

### Selective Sync

```bash
# Sync specific GitRepository
flux reconcile source git flux-system --context main

# Sync all GitRepositories
task flux:gr-sync cluster=main

# Sync all Kustomizations
task flux:ks-sync cluster=main

# Sync all HelmReleases
task flux:hr-sync cluster=main
```

### Force Sync Individual Resource

```bash
# Kustomization with source
flux reconcile kustomization myapp -n media --context main --with-source

# HelmRelease with source
flux reconcile hr myapp -n media --context main --with-source
```

---

## Working with Talos Nodes

### Cluster Context

Both clusters use Talos OS but have different configurations:

- **Main cluster**: 6 Intel NUC nodes
- **Staging cluster**: 3 Proxmox VMs

### Common Talos Commands

**Note**: Talos commands use the `TALOSCONFIG` environment variable for cluster selection, not `--context` flags.

```bash
# Check cluster health (requires TALOSCONFIG)
talosctl health --nodes <node-ip>

# Get node status
talosctl dashboard --nodes <node-ip>

# View logs
talosctl logs --nodes <node-ip> --tail 100

# Reboot node
talosctl reboot --nodes <node-ip>

# Apply configuration
talosctl apply-config --nodes <node-ip> --file kubernetes/main/talos/nodes/k8s-1.yaml

# Upgrade Talos
talosctl upgrade --nodes <node-ip> --image ghcr.io/siderolabs/installer:v1.x.x
```

### Node Maintenance

**Drain node before maintenance**:

```bash
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data --context main
```

**Uncordon after maintenance**:

```bash
kubectl uncordon <node-name> --context main
```

---

## Validating Manifests Before Push

### Kubeconform Validation

```bash
# Validate main cluster
task kubernetes:kubeconform cluster=main

# Validate staging cluster
task kubernetes:kubeconform cluster=staging
```

### What It Checks

- YAML syntax validity
- Kubernetes API schema compliance
- CRD validation (Flux, Gateway API, etc.)
- Kustomize build correctness

### Common Validation Errors

| Error                      | Cause                         | Fix                                     |
| -------------------------- | ----------------------------- | --------------------------------------- |
| **Invalid YAML**           | Syntax error                  | Check indentation, quotes, line breaks  |
| **Unknown field**          | Typo or wrong API version     | Verify field names, check API version   |
| **Missing required field** | Incomplete spec               | Add required fields per schema          |
| **Kustomize build failed** | Missing resource or bad patch | Check kustomization.yaml resources list |

---

## Managing Storage

### Rook/Ceph Storage

**Check cluster health**:

```bash
# Ceph status
kubectl exec -n rook-ceph deploy/rook-ceph-tools --context main -- ceph status

# OSD status
kubectl exec -n rook-ceph deploy/rook-ceph-tools --context main -- ceph osd status

# Pool usage
kubectl exec -n rook-ceph deploy/rook-ceph-tools --context main -- ceph df
```

**Create PVC** (automatic via HelmRelease persistence):

```yaml
persistence:
  data:
    enabled: true
    storageClass: rook-ceph-block
    size: 10Gi
    retain: true # Keep PVC on HelmRelease delete
```

**Troubleshoot PVC not binding**:

```bash
# Check PVC status
kubectl get pvc -n media --context main

# Describe PVC for events
kubectl describe pvc myapp-data -n media --context main

# Check Ceph operator logs
kubectl logs -n rook-ceph deploy/rook-ceph-operator --context main --tail=100
```

### NFS Storage

**Direct NFS mount** (no PVC needed):

```yaml
persistence:
  media:
    enabled: true
    type: nfs
    server: synology.internal
    path: /volume1/media
    globalMounts:
      - path: /media
        readOnly: false
```

**NFS CSI PVC** (if using democratic-csi or similar):

```yaml
persistence:
  media:
    enabled: true
    storageClass: nfs-client
    size: 100Gi
```

**Troubleshoot NFS mount**:

```bash
# Check pod events
kubectl describe pod <pod-name> -n media --context main

# Verify NFS server accessibility
task kubernetes:netshoot cluster=main
# In netshoot pod:
mount -t nfs synology.internal:/volume1/media /mnt
```

### VolSync Backups

**Trigger snapshot**:

```bash
# Single app
task volsync:snapshot cluster=main ns=media app=immich

# All apps
task volsync:snapshot-all cluster=main
```

**List snapshots**:

```bash
task volsync:list cluster=main ns=media app=immich
```

**Restore from snapshot**:

```bash
task volsync:restore cluster=main ns=media app=immich previous=<snapshot-name>
```

**Unlock stuck repository**:

```bash
task volsync:unlock cluster=main
```

---

## Checking Cluster Health

### Node Status

```bash
# Node overview
kubectl get nodes --context main

# Detailed node info
kubectl describe node <node-name> --context main

# Node resource usage
kubectl top nodes --context main
```

### Pod Health

```bash
# All pods
kubectl get pods -A --context main

# Failed/pending pods
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded --context main

# Delete failed pods
task kubernetes:delete-failed-pods cluster=main
```

### Resource Utilization

```bash
# Pod resource usage
kubectl top pods -A --context main

# Namespace resource quotas
kubectl describe resourcequota -A --context main
```

### Certificate Status

```bash
# Certificate resources
kubectl get certificates -A --context main

# Certificate requests
kubectl get certificaterequests -A --context main

# Approve pending certs (on bootstrap)
task kubernetes:approve-certs cluster=main
```

---

## Common Debugging Commands

### Both Clusters

**Note**: Replace `{main|staging}` with either `main` or `staging` depending on target cluster.

```bash
# List all HelmReleases
flux get hr -A --context {main|staging}

# List all Kustomizations
flux get ks --context {main|staging}

# List all ExternalSecrets
kubectl get es -A --context {main|staging}

# List all HTTPRoutes
kubectl get httproutes -A --context {main|staging}

# List all Gateways
kubectl get gateways -A --context {main|staging}
```

### Network Debugging

```bash
# Spawn netshoot pod for network troubleshooting
task kubernetes:netshoot cluster=main

# Inside netshoot pod:
# - nslookup <service>
# - curl http://<service>.<namespace>.svc.cluster.local
# - traceroute <ip>
# - tcpdump -i any port <port>
```

### Alpine/Ubuntu Debug Pods

```bash
# Alpine container
task kubernetes:alpine cluster=main

# Ubuntu container
task kubernetes:ubuntu cluster=main
```

### Check Specific App

```bash
# HelmRelease status
flux get hr myapp -n media --context main

# ExternalSecret status
kubectl get es myapp-secret -n media --context main

# Pod status
kubectl get pods -n media -l app.kubernetes.io/name=myapp --context main

# Pod logs
kubectl logs -n media -l app.kubernetes.io/name=myapp --context main --tail=100

# Pod describe (events)
kubectl describe pod <pod-name> -n media --context main

# Service endpoints
kubectl get endpoints myapp -n media --context main

# HTTPRoute status
kubectl describe httproute myapp -n media --context main
```

### Image Registry Debugging

```bash
# What images are from DockerHub
task kubernetes:what-dockerhub cluster=main

# Check image pull secrets
kubectl get secrets -A --context main | grep dockerconfig
```

---

## Database Operations (CloudNative-PG)

### Check Cluster Status

```bash
# PostgreSQL clusters
kubectl get clusters.postgresql.cnpg.io -A --context main

# Specific cluster
kubectl describe cluster immich -n media --context main

# Cluster pods
kubectl get pods -n media -l cnpg.io/cluster=immich --context main
```

### Maintenance Mode

```bash
# Main cluster - Enable maintenance (set in annotation on cluster)
task postgres:maintenance-main mode=on

# Main cluster - Disable maintenance
task postgres:maintenance-main mode=off

# Staging cluster - Enable maintenance
task postgres:maintenance-staging mode=on

# Staging cluster - Disable maintenance
task postgres:maintenance-staging mode=off
```

### Database Backups

```bash
# Check scheduled backups
kubectl get scheduledbackups -A --context main

# Manual backup
kubectl cnpg backup immich -n media --context main
```

### Immich-Specific Tasks

```bash
# Stop Immich
task postgres:down_immich cluster=main

# Restore Immich database
task postgres:restore_immich cluster=main

# Start Immich
task postgres:up_immich cluster=main
```

---

## Cluster Comparison Reference

### When to Use Main Cluster

- Production workloads
- Apps requiring high availability
- Media serving (Plex, Immich)
- Home automation (Home Assistant)
- Mission-critical services

### When to Use Staging Cluster

- Testing new apps before main deployment
- Validating configuration changes
- Experimenting with breaking changes
- Testing Flux/Talos upgrades

### Syncing Changes Between Clusters

Changes do NOT automatically sync. To deploy to both clusters:

```bash
# 1. Validate main
task kubernetes:kubeconform cluster=main

# 2. Deploy to main
git add kubernetes/main/apps/...
git commit -m "feat(myapp): add to main cluster"
git push

# 3. Copy/adapt for staging
cp -r kubernetes/main/apps/media/myapp kubernetes/staging/apps/media/

# 4. Update paths in staging manifests
# Edit kubernetes/staging/apps/media/myapp/install.yaml
# Change path: ./kubernetes/main/... to ./kubernetes/staging/...

# 5. Validate staging
task kubernetes:kubeconform cluster=staging

# 6. Deploy to staging
git add kubernetes/staging/apps/...
git commit -m "feat(myapp): add to staging cluster"
git push
```

---

## Pre-Commit Hooks

### Initialize

```bash
task pre-commit:init
```

### Run Manually

```bash
task pre-commit:run
```

### Update

```bash
task pre-commit:update
```

### What Pre-Commit Checks

- YAML formatting and syntax
- Markdown formatting
- Terraform formatting
- SOPS encryption validation
- Kubeconform validation
- Commit message format

---

## Evidence

| Claim                                         | Source                                                  | Confidence |
| --------------------------------------------- | ------------------------------------------------------- | ---------- |
| Task commands require cluster parameter       | `.taskfiles/*/Taskfile.yaml`                            | Verified   |
| Kubeconform validates both clusters           | `scripts/kubeconform.sh`, `kubernetes:kubeconform` task | Verified   |
| Apps use bjw-s/app-template                   | `kubernetes/{main,staging}/apps/*/app/helmrelease.yaml` | Verified   |
| ExternalSecrets sync from 1Password           | `kubernetes/{main,staging}/apps/*/app/secrets.yaml`     | Verified   |
| Flux reconciles via install.yaml entry points | `kubernetes/{main,staging}/apps/*/install.yaml`         | Verified   |
| VolSync handles backups via Restic            | `.taskfiles/volsync/Taskfile.yaml`                      | Verified   |
| Two independent clusters                      | `kubernetes/main/` and `kubernetes/staging/` separate   | Verified   |
| Image digests required                        | SHA256 digests in helmrelease.yaml files                | Verified   |

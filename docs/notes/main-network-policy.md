# Main Cluster Network Policy Recommendations

## Current State

The main cluster has **minimal network policy enforcement** - only one permissive NetworkPolicy exists for the flux-operator. Cilium v1.19.0 is running in allow-all mode by default.

### Existing Policy

```
kubernetes/main/apps/flux-system/flux-operator/app/networkpolicy.yaml
```
- Ingress only, allows traffic from all namespaces on ports 8080/9080

### Deployed Namespaces (67 apps total)

| Namespace | Key Workloads | Sensitivity |
|-----------|---------------|-------------|
| `kube-system` | cilium, coredns, metrics-server | Critical |
| `flux-system` | flux-operator, flux-instance | Critical |
| `cert-manager` | cert-manager | High |
| `external-secrets` | external-secrets, onepassword-connect | Critical |
| `dbms` | cloudnative-pg (3 replicas), dragonfly, pgadmin | Critical |
| `network` | envoy-gateway, cloudflare-tunnel, external-dns, multus | High |
| `observability` | prometheus, grafana, loki, hubble-ui, alloy | Medium |
| `media` | immich (with dedicated postgres), calibre-web, plex | Medium |
| `downloads` | sonarr, radarr, prowlarr, sabnzbd, qbittorrent, etc. (13 apps) | Low |
| `self-hosted` | homepage, wikijs, atuin, shlink, etc. (10 apps) | Medium |
| `home` | home-assistant | Medium |
| `system` | kopia, volsync, openebs, keda, spegel, etc. | High |
| `rook-ceph` | ceph cluster | Critical |
| `actions-runner-system` | github-actions-runner (cluster-admin!) | Critical |
| `renovate` | renovate-operator | Medium |
| `system-upgrade` | tuppr | High |

### LoadBalancer IP Assignments (External Exposure)

| IP | Service | Risk |
|----|---------|------|
| 10.11.0.15 | Kubernetes API (main.zinn.tech) | Critical |
| 10.11.1.10 | PostgreSQL (postgres.zinn.ca) | Critical |
| 10.11.1.12 | Dragonfly/Redis (redis.zinn.ca) | High |
| 10.11.1.19 | Immich PostgreSQL (immich.zinn.ca) | High |
| 10.11.1.21 | Envoy Internal Gateway | Medium |
| 10.11.1.22 | Envoy External Gateway | Medium |

---

## Recommended Policies

### 1. Cluster-Wide Foundation Policies

#### Allow DNS (required by all pods)

```yaml
apiVersion: cilium.io/v2
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: allow-dns
spec:
  endpointSelector: {}
  egress:
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
            k8s-app: kube-dns
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
            - port: "53"
              protocol: TCP
```

#### Allow kube-apiserver Access

```yaml
apiVersion: cilium.io/v2
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: allow-kube-apiserver
spec:
  endpointSelector: {}
  egress:
    - toEntities:
        - kube-apiserver
```

#### Allow Intra-Namespace Communication

```yaml
apiVersion: cilium.io/v2
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: allow-intra-namespace
spec:
  endpointSelector: {}
  ingress:
    - fromEndpoints:
        - {}  # Same namespace only (implicit)
  egress:
    - toEndpoints:
        - {}  # Same namespace only (implicit)
```

### 2. Critical Infrastructure Policies

#### dbms Namespace - PostgreSQL

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: postgres-cluster
  namespace: dbms
spec:
  endpointSelector:
    matchLabels:
      cnpg.io/cluster: postgres
  ingress:
    # Apps that need database access
    - fromEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: self-hosted
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: home
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: downloads
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: observability
      toPorts:
        - ports:
            - port: "5432"
              protocol: TCP
    # pgAdmin access
    - fromEndpoints:
        - matchLabels:
            app.kubernetes.io/name: pgadmin
      toPorts:
        - ports:
            - port: "5432"
              protocol: TCP
    # Internal network (LoadBalancer clients)
    - fromCIDR:
        - 10.0.0.0/8
      toPorts:
        - ports:
            - port: "5432"
              protocol: TCP
    # CNPG operator and replication
    - fromEndpoints:
        - matchLabels:
            app.kubernetes.io/name: cloudnative-pg
      toPorts:
        - ports:
            - port: "5432"
              protocol: TCP
            - port: "8000"
              protocol: TCP
  egress:
    # Replication between replicas
    - toEndpoints:
        - matchLabels:
            cnpg.io/cluster: postgres
      toPorts:
        - ports:
            - port: "5432"
              protocol: TCP
    # Backup to storage
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: rook-ceph
```

#### dbms Namespace - Dragonfly (Redis)

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: dragonfly
  namespace: dbms
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: dragonfly
  ingress:
    # Apps using Redis
    - fromEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: self-hosted
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: downloads
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: home
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: media
      toPorts:
        - ports:
            - port: "6379"
              protocol: TCP
    # Internal network
    - fromCIDR:
        - 10.0.0.0/8
      toPorts:
        - ports:
            - port: "6379"
              protocol: TCP
```

#### external-secrets Namespace

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: onepassword-connect
  namespace: external-secrets
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: onepassword-connect
  ingress:
    # Only external-secrets controller
    - fromEndpoints:
        - matchLabels:
            app.kubernetes.io/name: external-secrets
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
  egress:
    # 1Password API
    - toFQDNs:
        - matchName: my.1password.com
        - matchName: my.1password.eu
        - matchPattern: "*.1password.com"
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: external-secrets
  namespace: external-secrets
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: external-secrets
  egress:
    # To 1Password Connect
    - toEndpoints:
        - matchLabels:
            app.kubernetes.io/name: onepassword-connect
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
```

#### actions-runner-system (High Risk)

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: actions-runner
  namespace: actions-runner-system
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: actions-runner-controller
  ingress:
    # Webhook from GitHub
    - fromCIDR:
        - 0.0.0.0/0  # GitHub webhooks
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
  egress:
    # GitHub API
    - toFQDNs:
        - matchPattern: "*.github.com"
        - matchPattern: "*.githubusercontent.com"
        - matchName: api.github.com
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
    # Container registries
    - toFQDNs:
        - matchPattern: "*.ghcr.io"
        - matchPattern: "*.docker.io"
        - matchPattern: "*.docker.com"
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
```

### 3. Network Namespace Policies

#### Envoy Gateway

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: envoy-gateway
  namespace: network
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: envoy-gateway
  ingress:
    # External traffic (internal network)
    - fromCIDR:
        - 10.0.0.0/8
    # Cloudflare tunnel
    - fromEndpoints:
        - matchLabels:
            app.kubernetes.io/name: cloudflare-tunnel
  egress:
    # Route to any backend service
    - toEntities:
        - cluster
```

#### Cloudflare Tunnel

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: cloudflare-tunnel
  namespace: network
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: cloudflare-tunnel
  ingress: []  # No ingress needed
  egress:
    # Cloudflare edge
    - toFQDNs:
        - matchPattern: "*.cloudflareaccess.com"
        - matchPattern: "*.argotunnel.com"
        - matchPattern: "*.cloudflare.com"
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
            - port: "7844"
              protocol: TCP
    # To envoy gateway
    - toEndpoints:
        - matchLabels:
            app.kubernetes.io/name: envoy-gateway
```

### 4. Observability Namespace

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: prometheus
  namespace: observability
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: prometheus
  ingress:
    # Grafana queries
    - fromEndpoints:
        - matchLabels:
            app.kubernetes.io/name: grafana
      toPorts:
        - ports:
            - port: "9090"
              protocol: TCP
  egress:
    # Scrape all namespaces
    - toEntities:
        - cluster
      toPorts:
        - ports:
            - port: "9090"
              protocol: TCP
            - port: "9100"
              protocol: TCP
            - port: "8080"
              protocol: TCP
            - port: "8443"
              protocol: TCP
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: grafana
  namespace: observability
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: grafana
  ingress:
    # Gateway access
    - fromEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: network
      toPorts:
        - ports:
            - port: "3000"
              protocol: TCP
  egress:
    # Query Prometheus, Loki
    - toEndpoints:
        - matchLabels:
            app.kubernetes.io/name: prometheus
        - matchLabels:
            app.kubernetes.io/name: loki
      toPorts:
        - ports:
            - port: "9090"
              protocol: TCP
            - port: "3100"
              protocol: TCP
```

### 5. Media Namespace - Immich

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: immich-postgres
  namespace: media
spec:
  endpointSelector:
    matchLabels:
      cnpg.io/cluster: immich
  ingress:
    # Immich app only
    - fromEndpoints:
        - matchLabels:
            app.kubernetes.io/name: immich
      toPorts:
        - ports:
            - port: "5432"
              protocol: TCP
    # Internal network (LoadBalancer)
    - fromCIDR:
        - 10.0.0.0/8
      toPorts:
        - ports:
            - port: "5432"
              protocol: TCP
```

### 6. Downloads Namespace (Lower Trust)

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: downloads-default
  namespace: downloads
spec:
  endpointSelector: {}
  ingress:
    # Only from gateway
    - fromEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: network
  egress:
    # Internet access for downloads
    - toEntities:
        - world
    # Inter-app communication (arr stack)
    - toEndpoints:
        - {}
    # Database access
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: dbms
      toPorts:
        - ports:
            - port: "5432"
              protocol: TCP
            - port: "6379"
              protocol: TCP
```

---

## Implementation Strategy

### Phase 1: Observability (Week 1)

1. **Enable Hubble flow logging** (already enabled)
2. **Baseline traffic patterns** using Hubble UI
3. **Document actual traffic flows** between namespaces

### Phase 2: Foundation Policies (Week 2)

1. Deploy cluster-wide DNS and kube-apiserver policies
2. Deploy intra-namespace communication policy
3. **Test thoroughly** - these are prerequisites for everything

### Phase 3: Critical Infrastructure (Week 3-4)

| Priority | Namespace | Policy |
|----------|-----------|--------|
| 1 | `external-secrets` | Isolate 1Password Connect |
| 2 | `dbms` | PostgreSQL and Dragonfly access control |
| 3 | `actions-runner-system` | Restrict runner egress |
| 4 | `flux-system` | Tighten existing policy |

### Phase 4: Application Namespaces (Week 5+)

1. `network` - Gateway policies
2. `observability` - Prometheus/Grafana
3. `media` - Immich isolation
4. `downloads` - Lower trust zone
5. `self-hosted` - App-specific policies

---

## Security Priorities

### Critical Risks to Address

1. **GitHub Actions Runner** - Has cluster-admin; restrict network egress to GitHub only
2. **PostgreSQL LoadBalancer** - Exposed on 10.11.1.10; ensure only authorized clients connect
3. **OnePassword Connect** - Single point of failure for secrets; isolate strictly
4. **Flux Control Plane** - Controls all cluster state; tighten ingress

### Monitoring

Use Hubble to monitor policy violations:

```bash
# Watch denied traffic
hubble observe --verdict DROPPED

# Traffic to specific namespace
hubble observe --to-namespace dbms

# Generate policy suggestions
hubble observe --namespace <ns> -o jsonpb | cilium policy trace
```

---

## Notes

- Main cluster has 67 apps vs staging's ~15 - more complex policy matrix
- BGP is configured (ASN 65002 peering with 65001) for LoadBalancer IP advertisement
- Several databases are exposed via LoadBalancer - consider whether this is necessary
- The `downloads` namespace should be treated as lower-trust (external content)
- Observability stack needs broad access for metrics scraping

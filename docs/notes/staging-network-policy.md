# Staging Cluster Network Policy Recommendations

## Current State

The staging cluster currently has **no Cilium network policies** deployed. Cilium v1.19.0 is installed with Hubble enabled for observability.

### Deployed Namespaces

| Namespace | Key Workloads |
|-----------|---------------|
| `flux-system` | flux-operator, flux-instance |
| `kube-system` | cilium, coredns, metrics-server |
| `network` | envoy-gateway, external-dns |
| `cert-manager` | cert-manager |
| `external-secrets` | external-secrets, onepassword-connect |
| `dbms` | cloudnative-pg, dragonfly, pgadmin |
| `rook-ceph` | rook-ceph |
| `system` | kopia, reloader, spegel, volsync, etc. |
| `system-upgrade` | tuppr |
| `default` | whoami |
| `media` | (namespace only) |
| `self-hosted` | (namespace only) |

---

## Recommended Policies

### 1. Default Deny Policy (Foundation)

Start with default deny in each namespace to enforce least-privilege:

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: default-deny
  namespace: <namespace>
spec:
  endpointSelector: {}
  ingress:
    - fromEndpoints:
        - {} # deny all by default
  egress:
    - toEndpoints:
        - {} # deny all by default
```

### 2. Essential System Policies

#### Allow DNS (cluster-wide)

Every namespace needs DNS access:

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

#### Allow kube-apiserver Access (cluster-wide)

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

### 3. Namespace-Specific Policies

#### dbms namespace (PostgreSQL)

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: postgres-ingress
  namespace: dbms
spec:
  endpointSelector:
    matchLabels:
      cnpg.io/cluster: <cluster-name>
  ingress:
    # Allow from apps that need database access
    - fromEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: self-hosted
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: media
      toPorts:
        - ports:
            - port: "5432"
              protocol: TCP
    # Allow pgadmin
    - fromEndpoints:
        - matchLabels:
            app.kubernetes.io/name: pgadmin
      toPorts:
        - ports:
            - port: "5432"
              protocol: TCP
```

#### external-secrets namespace (1Password Connect)

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
    - fromEndpoints:
        - matchLabels:
            app.kubernetes.io/name: external-secrets
  egress:
    - toFQDNs:
        - matchName: my.1password.com
        - matchName: my.1password.eu
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
```

#### network namespace (Envoy Gateway)

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
    - fromCIDR:
        - 10.0.0.0/8  # Internal network
  egress:
    - toEndpoints:
        - {} # Allow to backend services
```

---

## Implementation Strategy

### Hubble-Based Approach (Recommended)

Since Hubble is already enabled, use an **observe-then-enforce** approach:

1. **Observe traffic first** using Hubble UI
2. **Generate policies** from observed flows:
   ```bash
   hubble observe --namespace <ns> -o jsonpb | \
     cilium policy trace --from-file -
   ```
3. **Start with audit mode** before enforcing

### Priority Order

| Priority | Namespace | Reason |
|----------|-----------|--------|
| 1 | `dbms` | Database access is most sensitive |
| 2 | `external-secrets` | Secrets provider needs isolation |
| 3 | `flux-system` | GitOps controller - high privilege |
| 4 | `rook-ceph` | Storage backend isolation |
| 5 | `network` | Gateway ingress rules |

---

## Notes

- Staging doesn't require production-level segmentation
- Use Hubble to monitor actual traffic patterns before adding restrictive policies
- The `media` and `self-hosted` namespaces are empty placeholders for future apps
- BGP is configured for LoadBalancer IP advertisement (ASN 65003 peering with 65001)

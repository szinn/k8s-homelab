---
description: Network architecture covering dual-cluster networks, Envoy Gateway routing, DNS resolution, and traffic flows
tags: ["Cilium", "EnvoyGateway", "GatewayAPI", "DNS", "Cloudflare", "DualCluster", "LoadBalancer"]
audience: ["LLMs", "Humans"]
categories: ["Architecture[100%]", "Networking[100%]"]
---

# Networking Architecture

## Network Overview

This homelab runs two independent Kubernetes clusters with isolated network ranges and separate Envoy Gateway instances for traffic routing.

---

## Capsule: DualClusterNetworks

**Invariant**
Main cluster uses 10.11.x.x network; staging cluster uses 10.12.x.x network; no network overlap or cross-cluster routing.

**Example**
Main cluster LoadBalancer IPs come from 10.11.1.2-127; staging cluster LoadBalancer IPs come from 10.12.1.2-127; clusters communicate only via external DNS/internet.
//BOUNDARY: Network isolation prevents accidental cross-cluster traffic.

**Depth**
- Distinction: Physical network separation ensures production isolation
- Trade-off: Cannot route directly between clusters but ensures clean separation
- Networks: Main uses VLAN 10.11.0.0/16, staging uses VLAN 10.12.0.0/16
- SeeAlso: `DualClusterIsolation`, `CiliumLoadBalancer`

---

## IP Address Map

### Main Cluster (10.11.x.x)

#### Cluster LoadBalancer IPs (Cilium LB-IPAM)

| IP | Service | Purpose |
|----|---------|---------|
| 10.11.1.21 | envoy-internal | Internal/LAN traffic gateway |
| 10.11.1.22 | envoy-external | External traffic gateway (via Cloudflare) |

#### IP Pools

| Range | Purpose |
|-------|---------|
| 10.11.0.15/32 | Reserved single IP |
| 10.11.1.2 - 10.11.1.127 | LoadBalancer IP pool |
| 10.201.0.0/16 | Pod CIDR (native routing) |
| 10.200.0.10 | CoreDNS service ClusterIP |

### Staging Cluster (10.12.x.x)

#### Cluster LoadBalancer IPs (Cilium LB-IPAM)

| IP | Service | Purpose |
|----|---------|---------|
| 10.12.1.21 | envoy-internal | Internal/LAN traffic gateway |
| 10.12.1.22 | envoy-external | External traffic gateway |

#### IP Pools

| Range | Purpose |
|-------|---------|
| 10.12.0.15/32 | Reserved single IP |
| 10.12.1.2 - 10.12.1.127 | LoadBalancer IP pool |
| 10.202.0.0/16 | Pod CIDR (native routing) |

---

## Envoy Gateway Routing

### Capsule: EnvoyGatewayPattern

**Invariant**
Apps route through Envoy Gateway using Gateway API HTTPRoute; external gateway for public traffic, internal gateway for LAN-only traffic.

**Example**
```yaml
route:
  internal-app:
    hostnames: ["home.${SECRET_DOMAIN}"]
    parentRefs:
      - name: envoy-internal
        namespace: network
    rules:
      - backendRefs:
          - name: home-assistant
            port: 8123
```
//BOUNDARY: HTTPRoute without parentRefs or with wrong gateway name fails to route traffic.

**Depth**
- Distinction: envoy-internal (10.11.1.21) vs envoy-external (10.11.1.22) control access path
- Trade-off: Explicit gateway selection vs implicit routing
- NotThis: Old Kubernetes Ingress resources (Gateway API is the standard)
- Pattern: Apps use `route:` section in HelmRelease with app-template chart
- SeeAlso: `HTTPRouteConfiguration`, `ExternalDNSIntegration`

---

### Gateway Configuration

#### Main Cluster Gateways

**envoy-external** (10.11.1.21)
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: envoy-external
  annotations:
    external-dns.alpha.kubernetes.io/target: external.${SECRET_DOMAIN}
spec:
  gatewayClassName: envoy
  infrastructure:
    annotations:
      lbipam.cilium.io/ips: 10.11.1.22
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      allowedRoutes:
        namespaces:
          from: All
      tls:
        certificateRefs:
          - kind: Secret
            name: wildcard-tls
```

**envoy-internal** (10.11.1.21)
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: envoy-internal
  annotations:
    external-dns.alpha.kubernetes.io/target: internal.${SECRET_DOMAIN}
spec:
  gatewayClassName: envoy
  infrastructure:
    annotations:
      lbipam.cilium.io/ips: 10.11.1.21
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      allowedRoutes:
        namespaces:
          from: All
      tls:
        certificateRefs:
          - kind: Secret
            name: wildcard-tls
```

**Key Features**:
- Both gateways support HTTP (port 80) with automatic redirect to HTTPS
- TLS termination at gateway with wildcard certificates
- Cross-namespace routing (`from: All`) allows any namespace to route through gateways
- Cilium LB-IPAM assigns specific IPs via annotation

---

### Capsule: HTTPRouteConfiguration

**Invariant**
HTTPRoute defines hostname, parent gateway, and backend service; external-dns watches HTTPRoute annotations to create DNS records.

**Example**
Internal-only app (Grafana):
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: grafana
spec:
  hostnames:
    - grafana.${SECRET_DOMAIN}
  parentRefs:
    - name: envoy-internal
      namespace: network
  rules:
    - backendRefs:
        - name: grafana-service
          port: 3000
```

**Depth**
- Components: hostnames (DNS names), parentRefs (which gateway), backendRefs (target service)
- Annotations: No explicit external-dns annotation means no DNS record created (manual DNS required)
- NotThis: HTTPRoute alone doesn't create DNS records without external-dns annotations
- Pattern: Most apps use app-template chart's `route:` helper which generates HTTPRoute
- SeeAlso: `EnvoyGatewayPattern`, `ExternalDNSIntegration`

---

## DNS Architecture

### Capsule: ExternalDNSIntegration

**Invariant**
external-dns-cloudflare watches HTTPRoutes with `external-dns.alpha.kubernetes.io/target` annotation and creates DNS records in Cloudflare.

**Example**
HTTPRoute with external-dns annotation:
```yaml
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/target: external.${SECRET_DOMAIN}
spec:
  hostnames:
    - app.${SECRET_DOMAIN}
```
Creates CNAME: `app.${SECRET_DOMAIN}` → `external.${SECRET_DOMAIN}` in Cloudflare.
//BOUNDARY: Missing annotation means no DNS record created; app unreachable from internet.

**Depth**
- Provider: Cloudflare DNS with API token from ExternalSecret
- Filter: Only processes HTTPRoutes matching `gateway-name=envoy-external`
- Proxied: Records created with Cloudflare proxy enabled (orange cloud)
- Ownership: Uses `txtOwnerId: "homelab"` and `txtPrefix: "k8s."` for tracking
- SeeAlso: `CloudflareTunnel`, `DNSResolution`

---

### Capsule: DNSResolution

**Invariant**
CoreDNS handles cluster DNS and forwards external queries to upstream resolver.

**Example**
Pod queries `grafana.${SECRET_DOMAIN}` → CoreDNS forwards to upstream resolver → returns appropriate IP based on DNS configuration.

**Depth**
- Service: CoreDNS runs on control plane nodes with ClusterIP 10.200.0.10 (main) / 10.200.0.10 (staging)
- Zones: `cluster.local` for internal cluster DNS, `.` forwarded to `/etc/resolv.conf`
- Plugins: kubernetes, forward, cache (30s prefetch), autopath, prometheus
- NotThis: No split-horizon DNS rewriting (unlike gavin-home-ops reference)
- SeeAlso: `ExternalDNSIntegration`

**CoreDNS Configuration**:
```yaml
servers:
  - zones:
      - zone: .
        scheme: dns://
        use_tcp: true
    plugins:
      - name: kubernetes
        parameters: cluster.local in-addr.arpa ip6.arpa
      - name: forward
        parameters: . /etc/resolv.conf
      - name: cache
        configBlock: |-
          prefetch 20
          serve_stale
```

---

## Cilium CNI

### Capsule: CiliumNetworking

**Invariant**
Cilium provides eBPF-based networking with native routing, LoadBalancer IP allocation, and Direct Server Return mode.

**Example**
Service with LoadBalancer type gets IP from Cilium pool:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: envoy-external
  annotations:
    lbipam.cilium.io/ips: 10.11.1.22
spec:
  type: LoadBalancer
```
Cilium assigns 10.11.1.22, traffic routes directly to service endpoints.

**Depth**
- Mode: Native routing with kube-proxy replacement (eBPF)
- LoadBalancer: DSR (Direct Server Return) mode for optimal performance
- BGP: Disabled (uses L2 announcements or relies on upstream router configuration)
- IPAM: Kubernetes mode with native routing CIDR (10.201.0.0/16 main, 10.202.0.0/16 staging)
- Features: BBR bandwidth manager, netkit datapath, socket LB
- SeeAlso: `CiliumLoadBalancer`

**Key Features Enabled**:

| Feature | Value | Purpose |
|---------|-------|---------|
| kubeProxyReplacement | true | eBPF-based service routing |
| loadBalancer.mode | dsr | Direct Server Return for client IP preservation |
| loadBalancer.algorithm | maglev | Consistent hashing load distribution |
| bandwidthManager | enabled, bbr: true | TCP BBR congestion control |
| bpf.masquerade | true | eBPF-based SNAT for pod egress |
| bpf.datapathMode | netkit | Modern eBPF datapath |
| routingMode | native | Native routing without encapsulation |
| autoDirectNodeRoutes | true | Direct node-to-node routing |

---

### Capsule: CiliumLoadBalancer

**Invariant**
Cilium LB-IPAM allocates LoadBalancer IPs from defined pools; services request specific IPs via annotation.

**Example**
Main cluster IP pool:
```yaml
apiVersion: cilium.io/v2
kind: CiliumLoadBalancerIPPool
metadata:
  name: main-pool
spec:
  allowFirstLastIPs: "Yes"
  blocks:
    - cidr: 10.11.0.15/32
    - start: 10.11.1.2
      stop: 10.11.1.127
```

**Depth**
- Allocation: Services annotated with `lbipam.cilium.io/ips: <IP>` get specific IP
- Pool: Main cluster uses 10.11.1.2-127, staging uses 10.12.1.2-127
- Mode: DSR mode means external client IP preserved to backend pods
- NotThis: No BGP advertisements (unlike gavin-home-ops which uses BGP to UDM Pro)
- SeeAlso: `CiliumNetworking`, `EnvoyGatewayPattern`

---

## Cloudflare Integration

### Capsule: CloudflareTunnel

**Invariant**
Cloudflared tunnel connects cluster to Cloudflare edge via QUIC; external traffic routes through tunnel to envoy-external gateway.

**Example**
Cloudflared configuration:
```yaml
ingress:
  - hostname: "*.${SECRET_DOMAIN}"
    originRequest:
      http2Origin: true
      originServerName: external.${SECRET_DOMAIN}
    service: https://envoy-external.network.svc.cluster.local:443
  - service: http_status:404
```

**Depth**
- Protocol: QUIC transport with post-quantum encryption
- Replicas: 2 pods for high availability
- Target: Routes all wildcard traffic to envoy-external gateway
- TLS: Uses http2Origin and validates against external.${SECRET_DOMAIN} certificate
- Environment: TUNNEL_TRANSPORT_PROTOCOL=quic, TUNNEL_POST_QUANTUM=true
- SeeAlso: `ExternalDNSIntegration`, `TrafficFlowExternal`

---

### Capsule: CloudflareProxy

**Invariant**
External-DNS creates proxied (orange cloud) Cloudflare DNS records; Cloudflare provides DDoS protection and CDN before routing to tunnel.

**Example**
external-dns creates CNAME with proxy enabled:
```
app.${SECRET_DOMAIN} → external.${SECRET_DOMAIN} (proxied)
```
Internet clients resolve to Cloudflare edge IP, traffic proxied through Cloudflare before tunnel.

**Depth**
- Flag: `--cloudflare-proxied` in external-dns configuration
- Protection: Cloudflare WAF, DDoS protection, rate limiting applied
- Trade-off: Extra hop but significant security and performance benefits
- NotThis: Unproxied DNS would expose tunnel endpoint directly
- SeeAlso: `CloudflareTunnel`, `TrafficFlowExternal`

---

## TLS and Certificate Management

### Capsule: CertManagerIntegration

**Invariant**
cert-manager issues wildcard certificates from Let's Encrypt; certificates referenced by Gateway TLS configuration.

**Example**
Wildcard certificate for main cluster:
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-tls
spec:
  secretName: wildcard-tls
  dnsNames:
    - "${SECRET_DOMAIN}"
    - "*.${SECRET_DOMAIN}"
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
```

**Depth**
- Issuer: Let's Encrypt production (ClusterIssuer)
- Challenge: DNS-01 via Cloudflare API (for wildcard certificates)
- Secret: Certificate stored in Secret, referenced by Gateway listeners
- Renewal: Automatic renewal before expiration
- Scope: Each gateway uses same wildcard certificate
- SeeAlso: `EnvoyGatewayPattern`, `TLSTermination`

---

### Capsule: TLSTermination

**Invariant**
TLS terminates at Envoy Gateway; backend communication uses HTTP within cluster.

**Example**
Gateway TLS configuration:
```yaml
listeners:
  - name: https
    protocol: HTTPS
    port: 443
    tls:
      mode: Terminate
      certificateRefs:
        - kind: Secret
          name: wildcard-tls
```

**Depth**
- Mode: Terminate (not Passthrough) - gateway decrypts traffic
- Backend: HTTPRoute backendRefs use HTTP to cluster services
- Certificates: Wildcard cert covers all subdomains
- Protocols: ALPN supports h2 (HTTP/2) and http/1.1
- MinVersion: TLS 1.2 minimum via ClientTrafficPolicy
- SeeAlso: `CertManagerIntegration`, `EnvoyGatewayPattern`

---

## Traffic Policies

### Capsule: ClientTrafficPolicy

**Invariant**
ClientTrafficPolicy configures client-facing behavior at gateway; applies to all HTTPRoutes using the gateway.

**Example**
```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: ClientTrafficPolicy
metadata:
  name: envoy
spec:
  clientIPDetection:
    xForwardedFor:
      trustedCIDRs:
        - 10.201.0.0/16  # Trust pod CIDR
  http2:
    initialStreamWindowSize: 2Mi
    initialConnectionWindowSize: 32Mi
  http3: {}
  targetSelectors:
    - group: gateway.networking.k8s.io
      kind: Gateway
  tls:
    minVersion: "1.2"
    alpnProtocols:
      - h2
      - http/1.1
```

**Depth**
- Target: Applies to all Gateway resources in namespace
- IP Detection: Trusts X-Forwarded-For from pod CIDR
- Protocols: HTTP/2, HTTP/3 enabled
- Timeouts: Configurable request timeouts (0s = disabled)
- SeeAlso: `BackendTrafficPolicy`, `EnvoyGatewayPattern`

---

### Capsule: BackendTrafficPolicy

**Invariant**
BackendTrafficPolicy configures backend communication; applies compression, timeouts, and connection settings.

**Example**
```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: BackendTrafficPolicy
metadata:
  name: envoy
spec:
  compression:
    - type: Zstd
    - type: Brotli
    - type: Gzip
  connection:
    bufferLimit: 64Mi
  timeout:
    http:
      requestTimeout: 0s  # No timeout
  targetSelectors:
    - group: gateway.networking.k8s.io
      kind: Gateway
```

**Depth**
- Compression: Negotiates best available (Zstd, Brotli, Gzip)
- Buffers: 64Mi backend buffer limit
- Timeouts: Disabled by default (0s)
- TCP: Keep-alive enabled
- SeeAlso: `ClientTrafficPolicy`, `EnvoyGatewayPattern`

---

## Traffic Flows

### Capsule: TrafficFlowExternal

**Invariant**
External internet traffic routes via Cloudflare edge → tunnel → envoy-external → HTTPRoute → service.

**Example**
User requests `app.${SECRET_DOMAIN}`:
1. DNS resolves to Cloudflare edge IP (proxied)
2. Cloudflare terminates TLS, applies WAF
3. Traffic tunnels via QUIC to cloudflared pod
4. cloudflared forwards to envoy-external:443
5. Envoy terminates TLS (again), routes via HTTPRoute
6. Backend service receives HTTP request

**Depth**
- Double TLS: Cloudflare terminates, then Envoy terminates (end-to-end encryption)
- Protocols: QUIC (internet → cluster), HTTP/2 (tunnel → gateway), HTTP (gateway → service)
- Protection: Cloudflare WAF, DDoS protection before reaching cluster
- SeeAlso: `CloudflareTunnel`, `EnvoyGatewayPattern`

---

### Capsule: TrafficFlowInternal

**Invariant**
Internal LAN traffic routes directly to envoy-internal gateway; no tunnel traversal.

**Example**
LAN client requests `grafana.${SECRET_DOMAIN}`:
1. DNS resolves to internal.${SECRET_DOMAIN} (manual DNS or upstream)
2. Client connects directly to 10.11.1.21:443
3. Envoy terminates TLS, routes via HTTPRoute
4. Backend service receives HTTP request

**Depth**
- Direct: No Cloudflare, no tunnel, direct HTTPS to gateway
- Performance: Lower latency than external path
- Access: Requires LAN or VPN access to reach 10.11.1.21
- DNS: Requires DNS configuration to resolve to internal gateway IP
- SeeAlso: `EnvoyGatewayPattern`, `TrafficFlowExternal`

---

## App Exposure Patterns

### Pattern 1: External-Only (Internet Access)

Apps accessible only from internet via Cloudflare tunnel.

**Configuration**:
```yaml
route:
  app:
    parentRefs:
      - name: envoy-external
        namespace: network
    # external-dns annotation creates Cloudflare DNS record
```

**Access**:
- Internet: Via Cloudflare → tunnel → envoy-external ✓
- LAN: Via Cloudflare → tunnel → envoy-external (hairpin)

---

### Pattern 2: Internal-Only (LAN Access)

Apps accessible only from LAN/VPN, no internet exposure.

**Configuration**:
```yaml
route:
  app:
    parentRefs:
      - name: envoy-internal
        namespace: network
    # No external-dns annotation
```

**Access**:
- Internet: No DNS record, unreachable ✗
- LAN: Direct to envoy-internal ✓

**Examples**: Grafana, internal monitoring tools

---

### Pattern 3: Dual-Homed (Not Currently Implemented)

Pattern where apps are accessible via both gateways (would require two HTTPRoutes or multiple parentRefs).

**Note**: Current implementation favors single-gateway pattern. Apps choose either external or internal, not both.

---

## Service Mesh Considerations

### Capsule: NoServiceMesh

**Invariant**
Cluster does not use a service mesh (Istio, Linkerd); Envoy Gateway provides edge routing only, not sidecar proxies.

**Example**
Pod-to-pod communication uses Cilium CNI directly; no service mesh mTLS or observability sidecars.

**Depth**
- Trade-off: Simpler architecture vs service mesh features (mTLS, advanced observability)
- Routing: Gateway API provides north-south traffic; Cilium provides east-west (pod-to-pod)
- NotThis: Envoy Gateway is not a service mesh, only an ingress/edge gateway
- SeeAlso: `CiliumNetworking`, `EnvoyGatewayPattern`

---

## Troubleshooting

### Check Gateway Status

```bash
# Main cluster
kubectl --context main get gateways -n network
kubectl --context main get httproutes -A

# Staging cluster
kubectl --context staging get gateways -n network
kubectl --context staging get httproutes -A
```

### Check DNS Resolution

```bash
# External perspective
dig app.${SECRET_DOMAIN} @1.1.1.1

# From main cluster
kubectl --context main run -it --rm debug --image=alpine -- nslookup app.${SECRET_DOMAIN}

# From staging cluster
kubectl --context staging run -it --rm debug --image=alpine -- nslookup app.${SECRET_DOMAIN}
```

### Check External-DNS

```bash
# Main cluster
kubectl --context main logs -n network -l app.kubernetes.io/name=external-dns-cloudflare

# Staging cluster
kubectl --context staging logs -n network -l app.kubernetes.io/name=external-dns-cloudflare
```

### Check Cilium LB-IPAM

```bash
# Main cluster
kubectl --context main get ciliumloadbalancerippool
kubectl --context main get services -A -o wide | grep LoadBalancer

# Staging cluster
kubectl --context staging get ciliumloadbalancerippool
kubectl --context staging get services -A -o wide | grep LoadBalancer
```

### Check Cloudflare Tunnel

```bash
# Main cluster
kubectl --context main logs -n network -l app.kubernetes.io/name=cloudflared
kubectl --context main get pods -n network -l app.kubernetes.io/name=cloudflared

# Staging cluster
kubectl --context staging logs -n network -l app.kubernetes.io/name=cloudflared
kubectl --context staging get pods -n network -l app.kubernetes.io/name=cloudflared
```

### Check Traffic Policies

```bash
# Main cluster
kubectl --context main get clienttrafficpolicy -n network
kubectl --context main get backendtrafficpolicy -n network
kubectl --context main describe clienttrafficpolicy envoy -n network

# Staging cluster
kubectl --context staging get clienttrafficpolicy -n network
kubectl --context staging get backendtrafficpolicy -n network
kubectl --context staging describe clienttrafficpolicy envoy -n network
```

---

## Evidence

| Claim | Source | Cluster | Confidence |
|-------|--------|---------|------------|
| Main cluster uses 10.11.x.x | `kubernetes/main/apps/kube-system/cilium/config/lb-pool.yaml:10` | main | Verified |
| Staging cluster uses 10.12.x.x | `kubernetes/staging/apps/kube-system/cilium/config/lb-pool.yaml:9` | staging | Verified |
| envoy-external at 10.11.1.22 | `kubernetes/main/apps/network/envoy-gateway/config/external.yaml:14` | main | Verified |
| envoy-internal at 10.11.1.21 | `kubernetes/main/apps/network/envoy-gateway/config/internal.yaml:14` | main | Verified |
| Staging envoy-internal at 10.12.1.21 | `kubernetes/staging/apps/network/envoy-gateway/config/internal.yaml:14` | staging | Verified |
| Cilium DSR mode | `kubernetes/main/apps/kube-system/cilium/app/helmrelease.yaml:117` | main | Verified |
| Cilium native routing | `kubernetes/main/apps/kube-system/cilium/app/helmrelease.yaml:143` | main | Verified |
| CoreDNS ClusterIP 10.200.0.10 | `kubernetes/main/apps/kube-system/coredns/app/helmrelease.yaml:22` | main | Verified |
| External-DNS Cloudflare proxied | `kubernetes/main/apps/network/external-dns/cloudflare/helmrelease.yaml:41` | main | Verified |
| Cloudflared QUIC transport | `kubernetes/main/apps/network/cloudflare-tunnel/app/helmrelease.yaml:47` | main | Verified |
| ClientTrafficPolicy trusts pod CIDR | `kubernetes/main/apps/network/envoy-gateway/config/envoy.yaml:75` | main | Verified |
| BackendTrafficPolicy compression | `kubernetes/main/apps/network/envoy-gateway/config/envoy.yaml:52-55` | main | Verified |
| Gateway wildcard TLS | `kubernetes/main/apps/network/envoy-gateway/config/internal.yaml:31` | main | Verified |

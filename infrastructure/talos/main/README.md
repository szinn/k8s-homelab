# Upgrading Talos

Determine which CP node is running the VIP port.

```shell
talosctl get addresses -n k8s-1,k8s-2,k8s-3,k8s-4,k8s-5,k8s-6 | grep 10.40.0.32
```

Upgrade the other two CP nodes first with:

```shell
talosctl upgrade --image ghcr.io/siderolabs/installer:v1.3.4 -n k8s-1
```

Upgrade the CP node running the VIP port.

Upgrade the worker nodes in order, verifying that the ceph cluster is healthy before upgrading the next one.

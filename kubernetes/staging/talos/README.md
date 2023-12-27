# Upgrading Talos

Determine which CP node is running the VIP port.

```shell
talosctl get addresses -n stage-1,stage-2,stage-3,stage-4,stage-5,stage-6 | grep 10.40.0.80
```

Upgrade the other two CP nodes first with:

```shell
talosctl upgrade --image ghcr.io/siderolabs/installer:v1.3.4 -n stage-1
```

Upgrade the CP node running the VIP port.

Upgrade the worker nodes in order, verifying that the ceph cluster is healthy before upgrading the next one.

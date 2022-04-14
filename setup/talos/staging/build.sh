#!/bin/bash

# Uncomment to generate new node configurations
# talosctl gen config "staging" "https://10.0.40.80:6443" --config-patch-control-plane @controlplane-patch.json --config-patch-worker @worker-patch.json

# Control plane configuration
cat controlplane.yaml | sed -e "s/!!HOSTNAME!!/stage-1/" > stage-1.yaml
cat controlplane.yaml | sed -e "s/!!HOSTNAME!!/stage-2/" > stage-2.yaml
cat controlplane.yaml | sed -e "s/!!HOSTNAME!!/stage-3/" > stage-3.yaml

# Worker configuration
cat worker.yaml | sed -e "s/!!HOSTNAME!!/stage-4/" > stage-4.yaml
cat worker.yaml | sed -e "s/!!HOSTNAME!!/stage-5/" > stage-5.yaml

# cat worker.yaml | sed -e "s/!!HOSTNAME!!/stage-6/" > stage-6.yaml

# Cluster running using Proxmox VMs for control plane nodes
talosctl apply-config -i -n 10.0.40.64 -f stage-1.yaml
talosctl apply-config -i -n 10.0.40.65 -f stage-2.yaml
talosctl apply-config -i -n 10.0.40.66 -f stage-3.yaml
talosctl apply-config -i -n 10.0.40.67 -f stage-4.yaml
talosctl apply-config -i -n 10.0.40.68 -f stage-5.yaml

#talosctl apply-config -i -n 10.0.40.21 -f k8s-6.yaml

talosctl --talosconfig=./talosconfig config endpoint 10.0.40.64 10.0.40.65 10.0.40.66
talosctl config merge ./talosconfig

# It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
# talosctl bootstrap -n 10.0.40.64

# It will then take a few more minutes for Kubernetes to get up and running on the nodes. Once ready, execute
# talosctl kubeconfig -n 10.0.40.64

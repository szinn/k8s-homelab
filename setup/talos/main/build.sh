#!/bin/bash

# Uncomment to generate new node configurations
# talosctl gen config "main" "https://10.0.40.32:6443" --config-patch-control-plane @controlplane-patch.json --config-patch-worker @worker-patch.json

# Control plane configuration
cat controlplane.yaml | sed -e "s/!!HOSTNAME!!/k8s-1/" > k8s-1.yaml
cat controlplane.yaml | sed -e "s/!!HOSTNAME!!/k8s-2/" > k8s-2.yaml
cat controlplane.yaml | sed -e "s/!!HOSTNAME!!/k8s-3/" > k8s-3.yaml

# Worker configuration
cat worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-4/" > k8s-4.yaml
cat worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-5/" > k8s-5.yaml
cat worker.yaml | sed -e "s/!!HOSTNAME!!/k8s-6/" > k8s-6.yaml

# Cluster running using Proxmox VMs for control plane nodes
talosctl apply-config -i -n 10.0.40.16 -f k8s-1.yaml
talosctl apply-config -i -n 10.0.40.17 -f k8s-2.yaml
talosctl apply-config -i -n 10.0.40.18 -f k8s-3.yaml
talosctl apply-config -i -n 10.0.40.19 -f k8s-4.yaml
talosctl apply-config -i -n 10.0.40.20 -f k8s-5.yaml
talosctl apply-config -i -n 10.0.40.21 -f k8s-6.yaml

talosctl --talosconfig=./talosconfig config endpoint 10.0.40.16 10.0.40.17 10.0.40.18
talosctl config merge ./talosconfig

# It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
# talosctl bootstrap -n 10.0.40.16

# It will then take a few more minutes for Kubernetes to get up and running on the nodes. Once ready, execute
# talosctl kubeconfig -n 10.0.40.16

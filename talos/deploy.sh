#!/bin/bash

# Only need to do this once since the config keys will always be the same
# talosctl --talosconfig=./clusterconfig/talosconfig config endpoint 10.0.40.16 10.0.40.17 10.0.40.18
# talosctl config merge ./clusterconfig/talosconfig
# talosctl kubeconfig -n 10.0.40.16

# Deploy the configuration to the nodes
talosctl apply-config -i -n 10.0.40.16 -f ./clusterconfig/main-k8s-1.yaml
talosctl apply-config -i -n 10.0.40.17 -f ./clusterconfig/main-k8s-2.yaml
talosctl apply-config -i -n 10.0.40.18 -f ./clusterconfig/main-k8s-3.yaml
talosctl apply-config -i -n 10.0.40.19 -f ./clusterconfig/main-k8s-4.yaml
talosctl apply-config -i -n 10.0.40.20 -f ./clusterconfig/main-k8s-5.yaml
talosctl apply-config -i -n 10.0.40.21 -f ./clusterconfig/main-k8s-6.yaml

# It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
# talosctl bootstrap -n 10.0.40.16
# curl http://router/main-cilium-quick-install.yaml | kubectl apply -f -

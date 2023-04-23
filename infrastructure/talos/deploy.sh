#!/bin/bash

# Only need to do this once since the config keys will always be the same
# talosctl --talosconfig=./clusterconfig/talosconfig config endpoint 10.11.0.16 10.11.0.17 10.11.0.18
# talosctl config merge ./clusterconfig/talosconfig
# talosctl kubeconfig -n 10.11.0.16

# Deploy the configuration to the nodes
talosctl apply-config -i -n k8s-1 -f ./clusterconfig/main-k8s-1.zinn.tech.yaml
talosctl apply-config -i -n k8s-2 -f ./clusterconfig/main-k8s-2.zinn.tech.yaml
talosctl apply-config -i -n k8s-3 -f ./clusterconfig/main-k8s-3.zinn.tech.yaml
talosctl apply-config -i -n k8s-4 -f ./clusterconfig/main-k8s-4.zinn.tech.yaml
talosctl apply-config -i -n k8s-5 -f ./clusterconfig/main-k8s-5.zinn.tech.yaml
talosctl apply-config -i -n k8s-6 -f ./clusterconfig/main-k8s-6.zinn.tech.yaml

# It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
# talosctl bootstrap -n k8s-1
# ./deploy-cni.sh

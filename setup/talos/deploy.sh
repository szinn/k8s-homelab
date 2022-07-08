#!/bin/bash

# Configure the control-plane nodes
talosctl apply-config -i -n 10.0.40.16 -f k8s-1.yaml
talosctl apply-config -i -n 10.0.40.17 -f k8s-2.yaml
talosctl apply-config -i -n 10.0.40.18 -f k8s-3.yaml

# Configure the worker nodes
talosctl apply-config -i -n 10.0.40.19 -f k8s-4.yaml
talosctl apply-config -i -n 10.0.40.20 -f k8s-5.yaml
talosctl apply-config -i -n 10.0.40.21 -f k8s-6.yaml

talosctl --talosconfig=./talosconfig config endpoint 10.0.40.16 10.0.40.17 10.0.40.18
talosctl config merge ./talosconfig

# It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
# talosctl --talosconfig=./talosconfig bootstrap -n 10.0.40.16

# It will then take a few more minutes for Kubernetes to get up and running on the nodes. Once ready, execute
# talosctl --talosconfig=./talosconfig kubeconfig -n 10.0.40.16

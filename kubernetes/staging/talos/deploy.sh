#!/bin/bash

# Only need to do this once since the config keys will always be the same
# talosctl --talosconfig=./clusterconfig/talosconfig config node 10.12.0.16 10.12.0.17 10.12.0.18 10.12.0.19 10.12.0.20 10.12.0.21
# talosctl --talosconfig=./clusterconfig/talosconfig config endpoint 10.12.0.16 10.12.0.17 10.12.0.18
# talosctl config merge ./clusterconfig/talosconfig
# talosctl kubeconfig -n stage-1.zinn.tech

# Deploy the configuration to the nodes
talosctl apply-config -i -n stage-1 -f ./clusterconfig/staging-stage-1.zinn.tech.yaml
talosctl apply-config -i -n stage-2 -f ./clusterconfig/staging-stage-2.zinn.tech.yaml
talosctl apply-config -i -n stage-3 -f ./clusterconfig/staging-stage-3.zinn.tech.yaml
talosctl apply-config -i -n stage-4 -f ./clusterconfig/staging-stage-4.zinn.tech.yaml
talosctl apply-config -i -n stage-5 -f ./clusterconfig/staging-stage-5.zinn.tech.yaml
talosctl apply-config -i -n stage-6 -f ./clusterconfig/staging-stage-6.zinn.tech.yaml

# It will take a few minutes for the nodes to spin up with the configuration.  Once ready, execute
# talosctl bootstrap -n stage-1.zinn.tech
# ./deploy-extras.sh

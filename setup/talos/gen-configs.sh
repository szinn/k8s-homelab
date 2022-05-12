#!/bin/bash

export REPO_ROOT=$(git rev-parse --show-toplevel)

. $REPO_ROOT/setup/setup-config.sh
. ${SETUP_CONFIG_ROOT}/env.base
. ${SETUP_CONFIG_ROOT}/env.main

# Name and IP for haproxy of the cluster API endpoint
export ZZ_API_HOSTNAME="main.${SECRET_DOMAIN_NAME}"
export ZZ_API_ADDR="10.0.40.32"
export ZZ_LOGGING_ADDR="${CONFIG_SVC_VECTOR_AGGREGATOR_ADDR}"

# Create the patch files from the template
cat controlplane-patch.json.template | envsubst > controlplane-patch.json
cat worker-patch.json.template | envsubst > worker-patch.json
talosctl gen config "main" "https://${ZZ_API_HOSTNAME}:6443" --config-patch-control-plane @controlplane-patch.json --config-patch-worker @worker-patch.json
# rm controlplane-patch.json worker-patch.json

# Control plane configuration
cat controlplane.yaml | sed -e "s/ZZ_HOSTNAME/k8s-1/" > k8s-1.yaml
cat controlplane.yaml | sed -e "s/ZZ_HOSTNAME/k8s-2/" > k8s-2.yaml
cat controlplane.yaml | sed -e "s/ZZ_HOSTNAME/k8s-3/" > k8s-3.yaml
cat controlplane.yaml | sed -e "s/ZZ_HOSTNAME/k8s-7/" > k8s-7.yaml

# Worker configuration
cat worker.yaml | sed -e "s/ZZ_HOSTNAME/k8s-4/" > k8s-4.yaml
cat worker.yaml | sed -e "s/ZZ_HOSTNAME/k8s-5/" > k8s-5.yaml
cat worker.yaml | sed -e "s/ZZ_HOSTNAME/k8s-6/" > k8s-6.yaml

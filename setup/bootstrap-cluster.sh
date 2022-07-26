#!/bin/bash
#
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

. ./common.sh
. ./setup-config.sh
. $SETUP_CONFIG_ROOT/env.base
. $SETUP_CONFIG_ROOT/env.main

echo "Bootstrapping cluster main"

flux install --export --network-policy=false | kubectl apply -f -
cat $SOPS_AGE_KEY_FILE | kubectl -n flux-system create secret generic sops-age --from-file=age.agekey=/dev/stdin
kubectl -n flux-system create secret generic github-deploy-key \
  --from-file=identity=${SETUP_CONFIG_ROOT}/id_${CONFIG_CLUSTER_NAME} \
  --from-file=identity.pub=${SETUP_CONFIG_ROOT}/id_${CONFIG_CLUSTER_NAME}.pub \
  --from-literal=known_hosts="github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
kubectl apply -f ../cluster/${CONFIG_CLUSTER_NAME}/flux-system/flux-installation.yaml
kubectl apply -f ../cluster/${CONFIG_CLUSTER_NAME}/flux-system/flux-cluster.yaml

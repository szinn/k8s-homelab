#!/bin/bash
#
CLUSTER_NAME="$1"
CLUSTER_BASE="${REPO_ROOT}/kubernetes/${CLUSTER_NAME}"

echo "Bootstrapping cluster ${CLUSTER_NAME}"

# Bootstrap Flux and CRDs
kubectl apply --server-side --kustomize ${CLUSTER_BASE}/bootstrap

# Bootstrap secrets decryption key
sops --decrypt ${CLUSTER_BASE}/bootstrap/age-key.sops.yaml | kubectl apply -f -

# kubectl -n flux-system create secret generic github-deploy-key \
#   --from-file=identity=${SETUP_CONFIG_ROOT}/id_${CLUSTER_NAME} \
#   --from-literal=known_hosts="github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="

# Bootstrap cluster configuration
kubectl apply -f ${CLUSTER_BASE}/cluster/vars/cluster-settings.yaml
sops --decrypt ${CLUSTER_BASE}/cluster/vars/cluster-secrets.sops.yaml | kubectl apply -f -

# Bootstrap the cluster
kubectl apply --server-side --kustomize ${CLUSTER_BASE}/cluster/config

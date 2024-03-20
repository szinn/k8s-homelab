#!/usr/bin/env bash

CLUSTER="$1"
NODE="$2"
NEW_IMAGE="$3"
ROLLOUT="${4:-false}"

echo "Cluster: $CLUSTER"
echo "Node: $NODE"
echo "New Image: $NEW_IMAGE"
echo "Rollout: $ROLLOUT"

# Get the current machine image
CURRENT_IMAGE="$(talosctl --context staging get  machineconfig -n $NODE -o json | jq -r '.spec.machine.install.image')"
echo "Current Image: $CURRENT_IMAGE"

if test "$CURRENT_IMAGE" == "$NEW_IMAGE"; then
  echo "Node $NODE already at image $NEW_IMAGE"
  exit 0
fi

echo "Upgrade required"

echo "Waiting for all jobs to complete before upgrading Talos ..."
until kubectl --context "$CLUSTER" wait --timeout=5m --for=condition=Complete jobs --all --all-namespaces; do
  echo "Waiting for jobs to complete ..."
  sleep 10
done

if [ "$ROLLOUT" != "true" ]; then
  echo "Suspending Flux Kustomizations ..."
  flux --context "$CLUSTER" suspend kustomization --all
  echo "Setting CNPG maintenance mode ..."
  task postgres:maintenance-$CLUSTER command=set
  kubectl cnpg --context "$CLUSTER" maintenance set --reusePVC --all-namespaces
fi

echo "Upgrading Talos on node $NODE in cluster $CLUSTER ..."
talosctl --context "$CLUSTER" upgrade -n "$NODE" --image "$NEW_IMAGE" --wait=true --timeout=10m

echo "Waiting for Talos to be healthy ..."
talosctl --context "$CLUSTER" --nodes "$NODE" health --wait-timeout=10m --server=false

echo "Waiting for Ceph health to be OK ..."
until kubectl --context "$CLUSTER" wait --timeout=5m --for=jsonpath=.status.ceph.health=HEALTH_OK cephcluster --all --all-namespaces; do
  echo "Waiting for Ceph health to be OK ..."
  sleep 10
done

if [ "$ROLLOUT" != "true" ]; then
  echo "Unsetting CNPG maintenance mode ..."
  task postgres:maintenance-$CLUSTER command=unset
  echo "Resuming Flux Kustomizations ..."
  flux --context "$CLUSTER" resume kustomization --all
fi

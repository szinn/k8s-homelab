#!/bin/bash
ROOK_WORKERS="k8s-4 k8s-5 k8s-6"
if ! test "$*" == ""; then
  ROOK_WORKERS="$*"
fi

for i in $ROOK_WORKERS; do
  echo "Wiping $i"
  cat wipe-rook.yaml | sed -e "s/HOSTNAME/$i/g" | kubectl apply -f -
  # cat wipe-rook-shell.yaml | sed -e "s/HOSTNAME/$i/g" | kubectl apply -f -
done

sleep 1

for i in $ROOK_WORKERS; do
  echo "Waiting for $i to complete"
  kubectl wait --timeout=900s --for=jsonpath='{.status.phase}=Succeeded' pod disk-wipe-$i -n default
  kubectl delete pod disk-wipe-$i
done

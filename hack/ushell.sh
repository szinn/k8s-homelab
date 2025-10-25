#!/bin/sh
kubectl apply -f hack/ubuntu.yaml
kubectl wait pod --for=condition=Ready=True ubuntu-shell
kubectl -n home exec -it ubuntu-shell -- bash
kubectl delete pod ubuntu-shell

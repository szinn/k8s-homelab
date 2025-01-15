#!/bin/sh
kubectl apply -f hack/alpine.yaml
kubectl wait pod --for=condition=Ready=True alpine-shell
kubectl -n default exec -it alpine-shell -- sh
kubectl delete pod alpine-shell

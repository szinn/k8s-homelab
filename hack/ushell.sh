#!/bin/sh
kubectl apply -f hack/ubuntu.yaml
kubectl -n default exec -it ubuntu-shell -- bash

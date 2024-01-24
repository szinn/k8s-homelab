#!/bin/bash

pushd extras >/dev/null 2>&1

if test -d cni/charts; then
  rm -rf cni/charts
fi
envsubst < ../../../../kubernetes/main/apps/kube-system/cilium/app/cilium-values.yaml > cni/values.yaml
kustomize build --enable-helm cni | kubectl apply -f -
# rm cni/values.yaml

if test -d csr-approver/charts; then
  rm -rf csr-approver/charts
fi
envsubst < ../../../../kubernetes/main/apps/kube-system/kubelet-csr-approver/app/values.yaml > csr-approver/values.yaml
kustomize build --enable-helm csr-approver | kubectl apply -f -
rm csr-approver/values.yaml
popd >/dev/null 2>&1

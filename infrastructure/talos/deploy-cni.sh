#!/bin/bash

if test -d charts; then
  rm -rf charts
fi

export CONFIG_HOME=$HOME/Development/k8s-config
. $CONFIG_HOME/env.base
. $CONFIG_HOME/env.main

pushd cni >/dev/null 2>&1
envsubst < ../../../kubernetes/apps/kube-system/cilium/app/cilium-values.yaml > values.yaml
kustomize build --enable-helm | kubectl apply -f -
rm values.yaml
popd >/dev/null 2>&1

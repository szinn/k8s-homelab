#!/bin/bash

export CONFIG_HOME=$HOME/Development/k8s-config
. $CONFIG_HOME/env.base
. $CONFIG_HOME/env.main

envsubst < cilium-values.yaml > values.yaml
kustomize build --enable-helm | kubectl apply -f -
rm values.yaml

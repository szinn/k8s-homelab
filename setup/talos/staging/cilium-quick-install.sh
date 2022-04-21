#!/bin/bash
helm template -f ./cilium-values.yaml cilium/cilium -n kube-system > ./cilium-quick-install.yaml

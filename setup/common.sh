#!/bin/bash

export REPO_ROOT=$(git rev-parse --show-toplevel)

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

message() {
  echo -e "\n######################################################################"
  echo "# $1"
  echo "######################################################################"
}

createNamespace() {
  kubectl wait --for=jsonpath='{.status.phase}'=Active namespace/$1 > /dev/null 2>&1
  if [ "$?" != 0 ]; then
    kubectl create namespace $1
  fi
}

#!/bin/bash

. ./common.sh
. ./setup-config.sh

need sops
need find

build_config() {
    export EXTENSION=$1
    shift
    TARGET=$1
    shift

  message "Building configuration for $TARGET"

  . $SETUP_CONFIG_ROOT/env.base
  if test -f  $SETUP_CONFIG_ROOT/env.$TARGET; then
    . $SETUP_CONFIG_ROOT/env.$TARGET
  fi

  for i in $*; do
    echo "Processing directory $i"
    find $REPO_ROOT/$i -type f -name "*.cfg" -exec $(dirname $0)/update-config.sh {} \;
    find $REPO_ROOT/$i -type f -name "*.cfg.sh" -exec $(dirname $0)/update-config.sh {} \;
  done
}

# build_config yml ansible ansible

build_config yaml common k8s/global
for i in $SETUP_CLUSTERS; do
  build_config yaml $i k8s/clusters/$i
done

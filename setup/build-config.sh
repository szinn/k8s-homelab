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
    echo "Loading configuration for $TARGET"
    . $SETUP_CONFIG_ROOT/env.$TARGET
  fi

  if test -d $REPO_ROOT/cluster/config/$TARGET; then
    for i in cluster-config.cfg cluster-secrets.sops.cfg; do
      if ! test -f $REPO_ROOT/cluster/config/$TARGET/$i; then
        touch $REPO_ROOT/cluster/config/$TARGET/$i
      fi
      if ! test -z "$(diff $i $REPO_ROOT/cluster/config/$TARGET/$i)"; then
        cp $i $REPO_ROOT/cluster/config/$TARGET
      fi
    done
  fi

  for i in $*; do
    echo "Processing directory $i"
    find $REPO_ROOT/$i -type f -name "*.cfg" -exec $(dirname $0)/update-config.sh {} \;
    find $REPO_ROOT/$i -type f -name "*.cfg.sh" -exec $(dirname $0)/update-config.sh {} \;
  done
}

for i in $SETUP_CLUSTERS; do
  build_config yaml $i cluster/config/$i
done

build_config yaml main cluster/core cluster/apps

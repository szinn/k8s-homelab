#!/bin/bash

APP_DIR="$(dirname $0)"

# Rebuild the configuration for a file and SOPS-encrypt if necessary.
rebuild_config() {
  SRC=$1
  SHAFILE=$2
  NEWSHA=$3
  BASE=${1%.cfg}
  DEST=$BASE.yaml

  echo "Rebuilding configuration for $1"

  envsubst < $SRC > $DEST
  if ! test "${BASE%.sops}" == $BASE; then
    sops --encrypt --in-place $DEST
  fi
  echo $NEWSHA > $SHAFILE
}

# Check and update the configuration for the given file if the sha doesn't match.
update_config() {
  if ! test "${1%.sh}" == "$1"; then
    CFGFILE=${1%.sh}
    . $1 > $CFGFILE
    update_config $CFGFILE
    rm $CFGFILE
  else
    SHAFILE=$1.sha256
    if ! test -e $SHAFILE; then
      echo "rebuild" > $SHAFILE
    fi

    NEWSHA=$(envsubst < $1  | shasum -a 256 | awk '{print $1}')
    OLDSHA=$(cat $SHAFILE)

    if ! test $NEWSHA == $OLDSHA; then
      rebuild_config $1 $SHAFILE $NEWSHA
    fi
  fi
}

# Process files in directory $1 of file extension $2
process_directory() {
  for file in $(find $REPO_ROOT/$1 -type f -name $2); do
    update_config $file
  done
}

# Build configurations for all .cfg/.cfg.sh files
build_config() {
  for i in $*; do
    echo "Processing directory $i"
    process_directory $i "*.cfg"
    process_directory $i "*.cfg.sh"
  done
}

build_config kubernetes/main

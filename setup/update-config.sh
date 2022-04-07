#!/bin/bash

if test "$(basename $1)" == "ansible.cfg"; then
  exit 0
fi

rebuild_config() {
  SRC=$1
  SHAFILE=$2
  NEWSHA=$3
  BASE=${1%.cfg}
  DEST=$BASE.$EXTENSION

  echo "Rebuilding configuration for $1"

  envsubst < $SRC > $DEST
  if ! test "${BASE%.sops}" == $BASE; then
    sops --encrypt --in-place $DEST
  fi
  echo $NEWSHA > $SHAFILE
}

if ! test "${1%.sh}" == "$1"; then
  CFGFILE=${1%.sh}
  . $1 > $CFGFILE
  $0 $CFGFILE
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

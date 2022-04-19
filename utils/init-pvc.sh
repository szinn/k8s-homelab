#!/bin/sh
# TARGET_DIR="THE_TARGET_DIR"
# SRC_FILE="THE_SRC_FILE"
# TEST_FILE="THE_TEST_FILE"

cd $TARGET_DIR
if ! test -f $TEST_FILE; then
  echo "Installing $SRC_FILE"
  tar xf $SRC_FILE
fi

#!/bin/bash

# Initialize environment for envsubst
. ../setup/common.sh
. ../setup/setup-config.sh
. $SETUP_CONFIG_ROOT/env.base
. $SETUP_CONFIG_ROOT/env.main

# Generate the configurations
talhelper genconfig

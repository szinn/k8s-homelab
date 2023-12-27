#!/bin/bash

# Initialize environment for envsubst
. $SETUP_CONFIG_ROOT/env.base
. $SETUP_CONFIG_ROOT/env.main

# Generate the configurations
talhelper genconfig

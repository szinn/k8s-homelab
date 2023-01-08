#!/bin/bash

# This points to where your env.base and env.<cluster> configuration files reside.
#
# Templates for these files are in this setup directory
export SETUP_CONFIG_ROOT="$HOME/Development/k8s-config"

# The list of clusters that are managed by this setup.
export SETUP_CLUSTER="main"

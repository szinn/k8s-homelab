#!/bin/bash

talosctl health --control-plane-nodes 10.10.0.16,10.10.0.17,10.10.0.18 --worker-nodes 10.10.0.19,10.10.0.20,10.10.0.21 -n $*

#!/bin/bash

talosctl health --control-plane-nodes 10.12.0.16,10.12.0.17,10.12.0.18 --worker-nodes 10.12.0.19,10.12.0.20,10.12.0.21 -n $*

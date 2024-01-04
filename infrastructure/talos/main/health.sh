#!/bin/bash

talosctl health --control-plane-nodes 10.11.0.16,10.11.0.17,10.11.0.18 --worker-nodes 10.11.0.19,10.11.0.20,10.11.0.21 -n $*

#!/bin/bash

# Reset the worker nodes first since the path to them is through the control plane nodes
talosctl reset --graceful=false --reboot -n 10.0.40.19
talosctl reset --graceful=false --reboot -n 10.0.40.20
talosctl reset --graceful=false --reboot -n 10.0.40.21

echo "Waiting for workers to reset... ^C to stop here"
sleep 5

# Reset the control plane nodes
talosctl reset --graceful=false --reboot -n 10.0.40.22
talosctl reset --graceful=false --reboot -n 10.0.40.23
talosctl reset --graceful=false --reboot -n 10.0.40.24

#!/bin/bash

# Reset the worker nodes first since the path to them is through the control plane nodes
talosctl reset --graceful=false --reboot -n 10.40.0.19 -e 10.40.0.19
talosctl reset --graceful=false --reboot -n 10.40.0.20 -e 10.40.0.20
talosctl reset --graceful=false --reboot -n 10.40.0.21 -e 10.40.0.21

echo "Waiting for workers to reset... ^C to stop here"
sleep 5

# Reset the control plane nodes
talosctl reset --graceful=false --reboot -n 10.40.0.16 -e 10.40.0.16
talosctl reset --graceful=false --reboot -n 10.40.0.17 -e 10.40.0.17
talosctl reset --graceful=false --reboot -n 10.40.0.18 -e 10.40.0.18

#!/bin/bash

# Reset the worker nodes first since the path to them is through the control plane nodes
talosctl reset --graceful=false --reboot -n 10.0.40.64
talosctl reset --graceful=false --reboot -n 10.0.40.65
talosctl reset --graceful=false --reboot -n 10.0.40.66

echo "Waiting for workers to reset... ^C to stop here"
sleep 5

# Reset the control plane nodes
talosctl reset --graceful=false --reboot -n 10.0.40.67
talosctl reset --graceful=false --reboot -n 10.0.40.68
talosctl reset --graceful=false --reboot -n 10.0.40.69

#!/bin/bash

# Reset the worker nodes first since the path to them is through the control plane nodes
talosctl reset --graceful=false --reboot -n k8s-4 -e k8s-4
talosctl reset --graceful=false --reboot -n k8s-5 -e k8s-5
talosctl reset --graceful=false --reboot -n k8s-6 -e k8s-6

echo "Waiting for workers to reset... ^C to stop here"
sleep 5

# Reset the control plane nodes
talosctl reset --graceful=false --reboot -n k8s-1 -e k8s-1
talosctl reset --graceful=false --reboot -n k8s-2 -e k8s-2
talosctl reset --graceful=false --reboot -n k8s-3 -e k8s-3

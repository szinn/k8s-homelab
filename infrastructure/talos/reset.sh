#!/bin/bash

# Reset the worker nodes first since the path to them is through the control plane nodes
talosctl reset --graceful=false --reboot -n k8s-4.zinn.tech -e k8s-4.zinn.tech
talosctl reset --graceful=false --reboot -n k8s-5.zinn.tech -e k8s-5.zinn.tech
talosctl reset --graceful=false --reboot -n k8s-6.zinn.tech -e k8s-6.zinn.tech

echo "Waiting for workers to reset... ^C to stop here"
sleep 5

# Reset the control plane nodes
talosctl reset --graceful=false --reboot -n k8s-1.zinn.tech -e k8s-1.zinn.tech
talosctl reset --graceful=false --reboot -n k8s-2.zinn.tech -e k8s-2.zinn.tech
talosctl reset --graceful=false --reboot -n k8s-3.zinn.tech -e k8s-3.zinn.tech

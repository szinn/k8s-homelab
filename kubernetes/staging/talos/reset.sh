#!/bin/bash

# Reset the worker nodes first since the path to them is through the control plane nodes
talosctl reset --reboot  --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL -n stage-4.zinn.tech -e stage-4.zinn.tech
talosctl reset --reboot  --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL -n stage-5.zinn.tech -e stage-5.zinn.tech
talosctl reset --reboot  --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL -n stage-6.zinn.tech -e stage-6.zinn.tech

echo "Waiting for workers to reset... ^C to stop here"
sleep 5

# Reset the control plane nodes
talosctl reset --reboot  --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL -n stage-1.zinn.tech -e stage-1.zinn.tech
talosctl reset --reboot  --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL -n stage-2.zinn.tech -e stage-2.zinn.tech
talosctl reset --reboot  --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL -n stage-3.zinn.tech -e stage-3.zinn.tech

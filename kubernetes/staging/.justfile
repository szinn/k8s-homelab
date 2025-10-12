#!/usr/bin/env -S just --justfile

set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

mod bootstrap "bootstrap"
mod proxmox "bootstrap/proxmox.just"
mod talos "talos"

[private]
default:
  just -l

[doc('Start the staging cluster')]
start:
  just proxmox start

[doc('Stop the staging cluster')]
stop:
  just proxmox stop

[doc('Reset the staging cluster')]
reset:
  just proxmox reset

[private]
log lvl msg *args:
  gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}

[private]
template file *args:
  minijinja-cli "{{ file }}" {{ args }} | op inject

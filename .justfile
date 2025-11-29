#!/usr/bin/env -S just --justfile

set unstable
set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

[private]
default:
    just -l

[doc('Run command for main cluster')]
main *args:
    export KUBECONFIG="{{ justfile_dir() }}/kubernetes/main/kubeconfig"; \
    export TALOSCONFIG="{{ justfile_dir() }}/kubernetes/main/talosconfig"; \
    just -f kubernetes/main/.justfile {{ args }}

[doc('Run command for staging cluster')]
staging *args:
    export KUBECONFIG="{{ justfile_dir() }}/kubernetes/staging/kubeconfig"; \
    export TALOSCONFIG="{{ justfile_dir() }}/kubernetes/staging/talosconfig"; \
    just -f kubernetes/staging/.justfile {{ args }}

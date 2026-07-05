#!/usr/bin/env -S just --justfile

set lazy
set positional-arguments
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

kubernetes_dir := justfile_dir()

[group: 'k8s-bootstrap']
mod bootstrap "bootstrap"

[group: 'proxmox']
mod proxmox "bootstrap/proxmox.just"

[group: 'talos']
mod talos "talos"

[private]
[script]
default:
    just -l

[doc('Start the staging cluster')]
[script]
start:
    just proxmox start

[doc('Stop the staging cluster')]
[script]
stop:
    just proxmox stop

[doc('Reset the staging cluster')]
[script]
reset:
    just proxmox reset

[doc('Rebuild the staging cluster')]
[script]
rebuild: reset
    just bootstrap

[doc('Browse a PVC')]
[script]
browse-pvc namespace claim:
    kubectl browse-pvc -n {{ namespace }} -i mirror.gcr.io/alpine:latest {{ claim }}

[doc('Open a shell on a node')]
[script]
node-shell node:
    kubectl debug node/{{ node }} -n default -it --image='mirror.gcr.io/alpine:latest' --profile sysadmin
    kubectl delete pod -n default -l app.kubernetes.io/managed-by=kubectl-debug

[doc('Prune pods in Failed, Pending, or Succeeded state')]
[script]
prune-pods:
    for phase in Failed Pending Succeeded; do
      kubectl delete pods -A --field-selector status.phase="$phase" --ignore-not-found=true
    done

[doc('Apply local Flux Kustomization')]
[script]
apply-ks ns ks:
    just render-local-ks "{{ ns }}" "{{ ks }}" | kubectl apply --force-confilcts --server-side --field-manager=kustomize-controller -f -

[doc('Delete local Flux Kustomization')]
[script]
delete-ks ns ks:
    just render-local-ks "{{ ns }}" "{{ ks }}" | kubectl delete -f -

[doc('Sync single Flux HelmRelease')]
[script]
sync-hr ns name:
    kubectl -n "{{ ns }}" annotate --field-manager flux-client-side-apply --overwrite hr "{{ name }}" reconcile.fluxcd.io/requestedAt="$(date +%s)" reconcile.fluxcd.io/forceAt="$(date +%s)"

[doc('Sync single Flux Kustomizations')]
[script]
sync-ks ns name:
    kubectl -n "{{ ns }}" annotate --field-manager flux-client-side-apply --overwrite ks "{{ name }}" reconcile.fluxcd.io/requestedAt="$(date +%s)"

[doc('Sync single ExternalSecret')]
[script]
sync-es ns name:
    kubectl -n "{{ ns }}" annotate --field-manager flux-client-side-apply --overwrite es "{{ name }}" force-sync="$(date +%s)"

[doc('Sync all Flux HelmReleases')]
[script]
sync-all-hr:
    kubectl get hr --no-headers -A | while read -r ns name _; do
      just k8s sync-hr "$ns" "$name"
    done

[doc('Sync all Flux Kustomizations')]
[script]
sync-all-ks:
    kubectl get ks --no-headers -A | while read -r ns name _; do
      just k8s sync-ks "$ns" "$name"
    done

[doc('Sync all ExternalSecrets')]
[script]
sync-all-es:
    kubectl get es --no-headers -A | while read -r ns name _; do
      just k8s sync-es "$ns" "$name"
    done

[private]
[script]
render-local-ks ns ks:
    staging justflux-local build ks --namespace "{{ ns }}" --path "{{ kubernetes_dir }}/cluster/config" "{{ ks }}"

[private]
[script]
log lvl msg *args:
    gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}

[private]
[script]
template file *args:
    minijinja-cli "{{ file }}" {{ args }} | op inject

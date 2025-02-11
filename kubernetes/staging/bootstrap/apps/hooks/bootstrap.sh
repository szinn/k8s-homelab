#!/usr/bin/env bash

set -euo pipefail

# Log messages with timestamps and function names
function log() {
    echo -e "\033[0;32m[$(date --iso-8601=seconds)] (${FUNCNAME[1]}) $*\033[0m"
}

# Wait for all nodes to be up
function wait_for_nodes() {
    if kubectl --context "${CLUSTER_CONTEXT}" wait nodes --for=condition=Ready --all --timeout=10s &>/dev/null; then
        log "All nodes are ready. Skipping..."
        return
    fi
    until kubectl --context "${CLUSTER_CONTEXT}" wait nodes --for=condition=Ready=False --all --timeout=10m &>/dev/null; do
        log "Waiting for all nodes to be up..."
        sleep 5
    done
}

# Apply Prometheus CRDs
function apply_prometheus_crds() {
    # renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator
    local -r version=v0.80.0

    local -r crds=(
        "alertmanagerconfigs"
        "alertmanagers"
        "podmonitors"
        "probes"
        "prometheusagents"
        "prometheuses"
        "prometheusrules"
        "scrapeconfigs"
        "servicemonitors"
        "thanosrulers"
    )

    for crd in "${crds[@]}"; do
        if kubectl --context "${CLUSTER_CONTEXT}" get crd "${crd}.monitoring.coreos.com" &>/dev/null; then
            log "Prometheus CRD '${crd}' is up-to-date. Skipping..."
            continue
        fi
        log "Applying Prometheus CRD '${crd}'..."
        kubectl --context "${CLUSTER_CONTEXT}" apply --server-side \
            --filename "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${version}/example/prometheus-operator-crd/monitoring.coreos.com_${crd}.yaml"
    done
}

# Apply bootstrap resources
function apply_bootstrap_config() {
    local -r env_file="${CLUSTER_DIR}/bootstrap/apps/.secrets.env"
    local -r template="${CLUSTER_DIR}/bootstrap/apps/templates/resources.yaml.j2"

    if op run --env-file "${env_file}" --no-masking -- minijinja-cli "${template}" \
        | kubectl --context "${CLUSTER_CONTEXT}" diff --filename - &>/dev/null;
    then
        log "Bootstrap resources are up-to-date. Skipping..."
        return
    fi

    log "Applying bootstrap resources..."
    op run --env-file "${env_file}" --no-masking -- minijinja-cli "${template}" | kubectl --context "${CLUSTER_CONTEXT}" apply --server-side --filename -
}

# Wipe Rook disks on the Talos nodes
function wipe_rook_disks() {
    if kubectl --context "${CLUSTER_CONTEXT}" --namespace rook-ceph get kustomization rook-ceph &>/dev/null; then
        log "Rook is deployed in the cluster. Skipping..."
        return
    fi

    for node in $(talosctl --context "${CLUSTER_CONTEXT}" config info --output json | jq --raw-output '.nodes | .[]'); do
        disk=$(
            talosctl --context "${CLUSTER_CONTEXT}" --nodes "${node}" get disks --output json \
                | jq --raw-output 'select(.spec.dev_path == "/dev/sdb") | .metadata.id' \
                | xargs
        )

        if [[ -n "${disk}" ]]; then
            log "Wiping disk '${disk}' on node '${node}'..."
            talosctl --nodes "${node}" wipe disk "${disk}"
        else
            log "No rook disks on node '${node}'. Skipping..."
        fi
    done
}

function main() {
    wait_for_nodes
    apply_prometheus_crds
    apply_bootstrap_config
    # wipe_rook_disks
}

main "$@"

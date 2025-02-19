#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC2155
export ROOT_DIR="$(git rev-parse --show-toplevel)"
# shellcheck disable=SC1091
source "${ROOT_DIR}/scripts/common.sh"

# Talos requires the nodes to be 'Ready=False' before applying resources
function wait_for_nodes() {
    log debug "Waiting for nodes to be available"

    # Skip waiting if all nodes are 'Ready=True'
    if kubectl_cmd wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then
        log info "Nodes are available and ready, skipping wait for nodes"
        return
    fi

    # Wait for all nodes to be 'Ready=False'
    until kubectl_cmd wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do
        log info "Nodes are not available, waiting for nodes to be available"
        sleep 10
    done
}

# Applications in the helmfile require Prometheus custom resources (e.g. servicemonitors)
function apply_prometheus_crds() {
    log debug "Applying Prometheus CRDs"

    # renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator
    local -r version=v0.80.0
    local resources crds

    # Fetch resources using kustomize build
    if ! resources=$(kustomize build "https://github.com/prometheus-operator/prometheus-operator/?ref=${version}" 2>/dev/null) || [[ -z "${resources}" ]]; then
        log error "Failed to fetch Prometheus CRDs, check the version or the repository URL"
    fi

    # Extract only CustomResourceDefinitions
    if ! crds=$(echo "${resources}" | yq '. | select(.kind == "CustomResourceDefinition")' 2>/dev/null) || [[ -z "${crds}" ]]; then
        log error "No CustomResourceDefinitions found in the fetched resources"
    fi

    # Check if the CRDs are up-to-date
    if echo "${crds}" | kubectl_cmd diff --filename - &>/dev/null; then
        log info "Prometheus CRDs are up-to-date"
        return
    fi

    # Apply the CRDs
    if echo "${crds}" | kubectl_cmd apply --server-side --filename - &>/dev/null; then
        log info "Prometheus CRDs applied successfully"
    else
        log error "Failed to apply Prometheus CRDs"
    fi
}

# The application namespaces are created before applying the resources
function apply_namespaces() {
    log debug "Applying namespaces"

    local -r apps_dir="${KUBERNETES_DIR}/apps"

    if [[ ! -d "${apps_dir}" ]]; then
        log error "Directory does not exist" directory "${apps_dir}"
    fi

    for app in "${apps_dir}"/*/; do
        namespace=$(basename "${app}")

        # Check if the namespace resources are up-to-date
        if  --context "${CLUSTER_CONTEXT}" get namespace "${namespace}" &>/dev/null; then
            log info "Namespace resource is up-to-date" resource "${namespace}"
            continue
        fi

        # Apply the namespace resources
        if kubectl_cmd create namespace "${namespace}" --dry-run=client --output=yaml \
            | kubectl_cmd apply --server-side --filename - &>/dev/null;
        then
            log info "Namespace resource applied" resource "${namespace}"
        else
            log error "Failed to apply namespace resource" resource "${namespace}"
        fi
    done
}

# Secrets to be applied before the helmfile charts are installed
function apply_secrets() {
    log debug "Applying secrets"

    local -r secrets_file="${KUBERNETES_DIR}/bootstrap/apps/resources/secrets.yaml.tpl"
    local resources

    if [[ ! -f "${secrets_file}" ]]; then
        log error "File does not exist" file "${secrets_file}"
    fi

    # Inject secrets into the template
    if ! resources=$(op inject --in-file "${secrets_file}" 2>/dev/null) || [[ -z "${resources}" ]]; then
        log error "Failed to inject secrets" file "${secrets_file}"
    fi

    # Check if the secret resources are up-to-date
    if echo "${resources}" | kubectl_cmd diff --filename - &>/dev/null; then
        log info "Secret resources are up-to-date"
        return
    fi

    # Apply secret resources
    if echo "${resources}" | kubectl_cmd apply --server-side --filename - &>/dev/null; then
        log info "Secret resources applied"
    else
        log error "Failed to apply secret resources"
    fi
}

# Disks in use by rook-ceph must be wiped before Rook is installed
function wipe_rook_disks() {
    log debug "Wiping Rook disks"

    if [[ -z "${ROOK_DISK:-}" ]]; then
        log error "Environment variable not set" env_var ROOK_DISK
    fi

    # Skip disk wipe if Rook is detected running in the cluster
    if  --context "${CLUSTER_CONTEXT}" --namespace rook-ceph get kustomization rook-ceph &>/dev/null; then
        log warn "Rook is detected running in the cluster, skipping disk wipe"
        return
    fi

    # Wipe disks on each node that match the ROOK_DISK environment variable
    for node in $(talosctl_cmd config info --output json | jq --raw-output '.nodes | .[]'); do
        disk=$(
            talosctl_cmd --nodes "${node}" get disks --output json \
                | jq --raw-output 'select(.spec.model == env.ROOK_DISK) | .metadata.id' \
                | xargs
        )

        if [[ -n "${disk}" ]]; then
            log debug "Discovered Talos node and disk" node "${node}" disk "${disk}"

            if talosctl_cmd --nodes "${node}" wipe disk "${disk}" &>/dev/null; then
                log info "Disk wiped" node "${node}" disk "${disk}"
            else
                log error "Failed to wipe disk" node "${node}" disk "${disk}"
            fi
        else
            log warn "No disks found" node "${node}" model "${ROOK_DISK:-}"
        fi
    done
}

function main() {
    # Verifications before bootstrapping the cluster
    check_env CLUSTER_CONTEXT
    check_cli helmfile jq kubectl kustomize minijinja-cli op talosctl yq

    wait_for_nodes
    apply_prometheus_crds
    apply_namespaces
    apply_secrets
    # wipe_rook_disks
}

main "$@"

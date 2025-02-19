#!/usr/bin/env bash

function wait_for_crds() {
    local -r crds=(
        "ciliuml2announcementpolicies" "ciliumbgppeeringpolicies" "ciliumloadbalancerippools"
    )

    for crd in "${crds[@]}"; do
        until kubectl --context staging get crd "${crd}.cilium.io" &>/dev/null; do
            echo "Waiting for CRD ${crd}..."
            sleep 10
        done
    done
}

function apply_config() {
    echo "Applying Cilium config"

    local -r cilium_config_dir="${ROOT_DIR}/kubernetes/staging/apps/kube-system/cilium/config"

    if [[ ! -d "${cilium_config_dir}" ]]; then
        echo "No Cilium config directory found" "file=${cilium_config_dir}"
    fi

    if kubectl --context staging --namespace kube-system diff --kustomize "${cilium_config_dir}" &>/dev/null; then
        echo "Cilium config is up-to-date"
    else
        if kubectl --context staging apply --namespace kube-system --server-side --field-manager kustomize-controller --kustomize "${cilium_config_dir}" &>/dev/null; then
            echo "Cilium config applied successfully"
        else
            echo "Failed to apply Cilium config"
        fi
    fi
}

function main() {
    wait_for_crds
    apply_config
}

main "$@"

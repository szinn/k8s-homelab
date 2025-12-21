#!/usr/bin/env bash
set -o errexit
set -o pipefail

KUBERNETES_DIR=$1

[[ -z "${KUBERNETES_DIR}" ]] && echo "Kubernetes location not specified" && exit 1

KUBERNETES_DIR=$(realpath "${KUBERNETES_DIR}")
REPO_ROOT=$(dirname "$(dirname "${KUBERNETES_DIR}")")

kustomize_args=("--load-restrictor=LoadRestrictionsNone")
kustomize_config="kustomization.yaml"
flux_config="install.yaml"
kubeconform_args=(
    "-strict"
    "-ignore-missing-schemas"
    "-skip"
    "Secret,ReplicationSource,ReplicationDestination"
    "-schema-location"
    "default"
    "-schema-location"
    "https://schemas.zinn.ca/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json"
    "-verbose"
)

declare -A flux_kustomize_paths=()
flux_kustomizations=()

while IFS= read -r -d $'\0' flux_file; do
    while IFS=$'\t' read -r flux_name flux_path; do
        if [[ -z "${flux_name}" || "${flux_name}" == "null" || -z "${flux_path}" || "${flux_path}" == "null" ]]; then
            continue
        fi
        flux_path="${flux_path#./}"
        flux_path_abs=$(realpath -m "${REPO_ROOT}/${flux_path}")
        flux_kustomize_paths["${flux_path_abs}"]=1
        flux_kustomizations+=("${flux_name}|${flux_path_abs}|${flux_file}")
    done < <(yq eval --no-doc '. | [.metadata.name, .spec.path] | @tsv' "${flux_file}")
done < <(find "${KUBERNETES_DIR}" -type f -name "${flux_config}" -print0)

echo "=== Validating standalone manifests in ${KUBERNETES_DIR}/flux ==="
find "${KUBERNETES_DIR}/cluster" -maxdepth 1 -type f -name '*.yaml' -print0 | while IFS= read -r -d $'\0' file; do
    echo "Running kubeconform on ${file} with arguments: ${kubeconform_args[@]}"
    kubeconform "${kubeconform_args[@]}" "${file}"
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        exit 1
    fi
done

echo "=== Validating kustomizations in ${KUBERNETES_DIR}/flux ==="
find "${KUBERNETES_DIR}/cluster" -type f -name $kustomize_config -print0 | while IFS= read -r -d $'\0' file; do
    echo "=== Validating kustomizations in ${file/%$kustomize_config/} ==="
    kustomize build "${file/%$kustomize_config/}" "${kustomize_args[@]}" |
        kubeconform "${kubeconform_args[@]}"
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        exit 1
    fi
done

echo "=== Validating kustomizations in ${KUBERNETES_DIR}/apps ==="
find "${KUBERNETES_DIR}/apps" -type f -name $kustomize_config -print0 | while IFS= read -r -d $'\0' file; do
    kustomize_dir=$(dirname "${file}")
    kustomize_dir_abs=$(realpath "${kustomize_dir}")
    if [[ -n "${flux_kustomize_paths["${kustomize_dir_abs}"]:-}" ]]; then
        echo "Skipping ${kustomize_dir} (handled via Flux build)"
        continue
    fi
    echo "=== Validating kustomizations in ${file/%$kustomize_config/} ==="
    kustomize build "${file/%$kustomize_config/}" "${kustomize_args[@]}" |
        kubeconform "${kubeconform_args[@]}"
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        exit 1
    fi
done

if [[ ${#flux_kustomizations[@]} -gt 0 ]]; then
    echo "=== Validating Flux Kustomizations ==="
    for flux_entry in "${flux_kustomizations[@]}"; do
        IFS='|' read -r flux_name flux_path_abs flux_file <<<"${flux_entry}"
        if [[ -z "${flux_name}" || -z "${flux_path_abs}" || -z "${flux_file}" ]]; then
            continue
        fi
        if [[ ! -d "${flux_path_abs}" ]]; then
            echo "Skipping ${flux_file} (path ${flux_path_abs} not found)"
            continue
        fi
        echo "=== Validating Flux kustomization ${flux_name} at ${flux_path_abs} ==="
        if ! flux build kustomization "${flux_name}" \
            --path "${flux_path_abs}" \
            --kustomization-file "${flux_file}" \
            --dry-run |
            kubeconform "${kubeconform_args[@]}"; then
            exit 1
        fi
    done
fi

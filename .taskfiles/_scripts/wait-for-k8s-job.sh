#!/usr/bin/env bash

JOB_NAME=$1
NAMESPACE="${2:-default}"
CLUSTER=$3

[[ -z "${JOB_NAME}" ]] && echo "Job name not specified" && exit 1

while true; do
    STATUS="$(kubectl --context "${CLUSTER}" -n "${NAMESPACE}" get pod -l job-name="${JOB_NAME}" -o jsonpath='{.items[*].status.phase}')"
    if [[ "${STATUS}" == "Succeeded" ]]; then
        break
    fi
    sleep 1
done

#!/bin/bash
kubectl -n dev --dry-run=client create secret generic actions-runner-controller-auth -o yaml \
  --from-literal=github_app_id=${GITHUB_APP_ID} \
  --from-literal=github_app_installation_id=${GITHUB_INSTALLATION_ID} \
  --from-file=github_app_private_key=${GITHUB_PRIVATE_KEY_FILE_PATH}

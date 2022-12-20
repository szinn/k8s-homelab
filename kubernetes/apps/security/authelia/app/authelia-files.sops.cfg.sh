#!/bin/bash
kubectl -n security --dry-run=client create secret generic authelia-files -o yaml \
  --from-file=users.yaml=${SETUP_CONFIG_ROOT}/authelia-users.yaml \
  --from-file=issuer-private-key=${SETUP_CONFIG_ROOT}/authelia-oidc-private.pem

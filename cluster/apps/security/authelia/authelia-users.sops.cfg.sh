#!/bin/bash
kubectl -n security --dry-run=client create secret generic authelia-users -o yaml \
  --from-file=users.yaml=${SETUP_CONFIG_ROOT}/authelia-users.yaml

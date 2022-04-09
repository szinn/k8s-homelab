#!/bin/bash
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode | pbcopy && echo "Copied to clipboard"

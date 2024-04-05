#!/bin/bash

kubectl scale --replicas 0 -n self-hosted deployment 'shlink-api'
kubectl --context main -n self-hosted wait pod --for delete --selector="app.kubernetes.io/name=shlink-api" --timeout=2m

echo 'DROP DATABASE IF EXISTS shlink;' | psql

psql < shlink-latest.sql

kubectl scale --replicas 1 -n self-hosted deployment 'shlink-api'

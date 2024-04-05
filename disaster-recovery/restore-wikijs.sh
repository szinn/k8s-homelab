#!/bin/bash

kubectl scale --replicas 0 -n self-hosted deployment wikijs
kubectl --context main -n self-hosted wait pod --for delete --selector="app.kubernetes.io/name=wikijs" --timeout=2m

echo 'DROP DATABASE IF EXISTS wikijs;' | psql

psql < wikijs-latest.sql

kubectl scale --replicas 1 -n self-hosted deployment wikijs

#!/bin/bash

kubectl scale --replicas 0 -n monitoring deployment teslamate
kubectl --context main -n monitoring wait pod --for delete --selector="app.kubernetes.io/name=teslamate" --timeout=2m

echo 'DROP DATABASE IF EXISTS teslamate;' | psql

psql < teslamate-latest.sql

kubectl scale --replicas 1 -n monitoring deployment teslamate

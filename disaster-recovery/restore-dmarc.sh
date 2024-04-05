#!/bin/bash

kubectl scale --replicas 0 -n security statefulset 'dmarc-report'
kubectl --context main -n security wait pod --for delete --selector="app.kubernetes.io/name=dmarc-report" --timeout=2m
sleep 5

echo 'DROP DATABASE IF EXISTS dmarc;' | psql

psql < dmarc-latest.sql

kubectl scale --replicas 1 -n security statefulset 'dmarc-report'

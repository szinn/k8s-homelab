#!/bin/bash

kubectl scale --replicas 0 -n media deployment immich-microservices
kubectl scale --replicas 0 -n media deployment immich-redis
kubectl scale --replicas 0 -n media deployment immich-server
kubectl --context main -n media wait pod --for delete --selector="app.kubernetes.io/name=immich-microservices" --timeout=2m
kubectl --context main -n media wait pod --for delete --selector="app.kubernetes.io/name=immich-server" --timeout=2m

echo 'DROP DATABASE IF EXISTS immich;' | psql -h immich.zinn.ca

psql -h immich.zinn.ca < immich-latest.sql

kubectl scale --replicas 1 -n media deployment immich-microservices
kubectl scale --replicas 1 -n media deployment immich-redis
kubectl scale --replicas 1 -n media deployment immich-server

#!/bin/bash
. ~/.config/k8s-homelab/env.base
mc admin user add s3 loki $LOKI_S3_PASSWORD
mc mb --region ca-wat-1 s3/loki
mc admin policy add s3 loki-private loki-user-policy.json
mc admin policy set s3 loki-private user=loki

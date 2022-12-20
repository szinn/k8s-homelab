#!/bin/bash
. $HOME/Development/k8s-config/env.base
mc admin user add s3 thanos $THANOS_S3_PASSWORD
mc mb --region ca-wat-1 s3/thanos
mc admin policy add s3 thanos-private thanos-user-policy.json
mc admin policy set s3 thanos-private user=thanos

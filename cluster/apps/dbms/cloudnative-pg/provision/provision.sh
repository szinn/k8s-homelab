#!/bin/bash
. $HOME/Development/k8s-config/env.base
mc admin user add s3 postgresql $POSTGRESQL_S3_PASSWORD
mc mb --region ca-wat-1 s3/postgresql
mc admin policy add s3 postgresql-private postgresql-user-policy.json
mc admin policy set s3 postgresql-private user=postgresql

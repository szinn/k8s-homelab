#!/bin/bash
. $HOME/Development/k8s-config/env.base
mc admin user add s3 volsync $VOLSYNC_S3_PASSWORD
mc mb --region $MINIO_REGION s3/volsync
mc admin policy add s3 volsync-private volsync-user-policy.json
mc admin policy set s3 volsync-private user=volsync

#!/bin/bash
. ~/.config/k8s-homelab/env.base

echo -n '{"db":0,"sentinels":[{"host":"redis-node-0.redis-headless.dbms.svc.cluster.local","port":26379},{"host":"redis-node-1.redis-headless.dbms.svc.cluster.local","port":26379},{"host":"redis-node-2.redis-headless.dbms.svc.cluster.local","port":26379}],"name":"redis-master"}' | base64 -i -
# Use this base64 encoded string in the Kubernetes secret
#    ```yaml
#    REDIS_URL: ioredis://eyJkYiI6MTUsInNlbnRpbmVscyI6W3siaG9zdCI6InJlZGlzLW5vZGUtMC5yZWRpcy1oZWFkbGVzcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwicG9ydCI6MjYzNzl9LHsiaG9zdCI6InJlZGlzLW5vZGUtMS5yZWRpcy1oZWFkbGVzcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwicG9ydCI6MjYzNzl9LHsiaG9zdCI6InJlZGlzLW5vZGUtMi5yZWRpcy1oZWFkbGVzcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwicG9ydCI6MjYzNzl9XSwibmFtZSI6InJlZGlzLW1hc3RlciJ9
#    ```

mc admin user add s3 outline $OUTLINE_S3_PASSWORD
mc mb --region ca-wat-1 s3/outline
mc admin policy add s3 outline-private outline-user-policy.json
mc admin policy set s3 outline-private user=outline
mc policy set-json bucket-policy.json s3/outline

#!/bin/bash

kubectl -n web-tools --dry-run=client create secret generic dashy-code-server-secret -o yaml --from-file=id_rsa=$HOME/.ssh/id_rsa

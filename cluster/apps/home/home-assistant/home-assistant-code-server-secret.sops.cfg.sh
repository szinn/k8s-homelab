#!/bin/bash

kubectl -n home --dry-run=client create secret generic home-assistant-code-server -o yaml --from-file=id_rsa=$HOME/.ssh/id_rsa

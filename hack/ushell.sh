#!/bin/sh
 kubectl apply -f ubuntu.yaml
 kubectl -n default exec -it ubuntu-shell -- bash

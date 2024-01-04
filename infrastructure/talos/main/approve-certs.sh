#!/bin/bash

kubectl certificate approve $(kubectl get csr --sort-by=.metadata.creationTimestamp | grep Pending | awk '{print $1}')

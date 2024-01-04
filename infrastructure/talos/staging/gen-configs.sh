#!/bin/bash

# Generate the configurations
talhelper genconfig --env-file talenv.sops.yaml --secret-file talsecret.sops.yaml --config-file talconfig.yaml

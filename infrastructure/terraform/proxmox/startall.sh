#!/bin/bash
VMS="201 202 203 204 205 206"

for i in $VMS; do
  ssh ares -- qm start $i
done

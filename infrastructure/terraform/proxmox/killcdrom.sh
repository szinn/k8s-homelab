#!/bin/bash
VMS="201 202 203 204 205 206"

for i in $VMS; do
  ssh ares -- qm set $i -ide2 media=cdrom,file=none
done

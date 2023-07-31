#!/bin/sh

# read running vms and shut them down
for vm in $(qm list | grep "running" | awk -F " " '{print$1}'); do (qm shutdown $vm) done

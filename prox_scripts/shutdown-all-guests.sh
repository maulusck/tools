#!/bin/sh

# read running vms and shut them down
for vm in $(qm list | grep "running" | awk -F " " '{print$1}'); do (echo "Shutting down VM $vm..." ; qm shutdown $vm) done

# read running cts and shut them down
for ct in $(pct list | grep "running" | awk -F " " '{print$1}'); do (echo "Shutting down CT $ct..." ; pct shutdown $ct) done

echo "Done."

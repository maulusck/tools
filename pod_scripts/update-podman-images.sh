#!/bin/sh
set -e
for image in $(podman images --noheading | grep -vE '<none>|localhost' | awk -F " " '{print$1 ":" $2}'); do podman pull $image; done
podman image prune -f

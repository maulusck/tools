#!/bin/sh
set -e
for image in $(podman images --noheadings | grep -v 'localhost' | awk -F " " '{print$1 ":" $2}'); do podman pull $image; done
podman image prune -f

#!/bin/sh
# fetch new images
for image in $(podman images | grep -vE 'localhost|REPO' | awk -F " " '{print$1 ":" $2}'); do podman pull $image; done
# prune blobs
podman image prune -f

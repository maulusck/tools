#!/bin/sh
podman rm -f $(podman ps --all --storage -q) 2>/dev/null
podman image prune -f

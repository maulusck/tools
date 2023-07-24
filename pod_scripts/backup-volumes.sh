#!/bin/sh
set -e

# env vars
#source .env

BAK_DIR="/srv/bak/podman/pod_volumes"

VOLUMES=$(podman volume ls  | grep -w local | awk -F " " '{print$2}')
for volume in $VOLUMES ; do
        echo "Backing up $volume in $BAK_DIR/$volume..."
        [ -d $BAK_DIR/$volume ] || mkdir -p $BAK_DIR/$volume
        podman volume export $volume > $BAK_DIR/$volume/$volume-$(date -Iminutes | sed 's|:|-|g; s|+|-|g').tar
done

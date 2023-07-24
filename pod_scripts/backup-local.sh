#!/bin/sh
set -e

LOCAL="${HOME}/local"
BAK_DIR="/srv/bak/podman/local"

# do backup
test -d ${LOCAL} || exit 1
tar cvzf ${BAK_DIR}/local-$(date -I).tgz -C $(dirname ${LOCAL}) $(basename ${LOCAL})

#!/bin/sh
set -e
. "$(dirname "$0")/env.sh"
echo "Pruning directories while keeping last $KEEP backups in $BACKUP."
read -p "Press ENTER to confirm: " a
find /srv/bak/containers/* -maxdepth 1 -type f | xargs ls -1t | tail -n +$((KEEP+1)) | xargs -r rm -rfv

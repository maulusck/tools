#!/bin/sh
set -e
. "$(dirname "$0")/env.sh"
echo "Pruning $CT_BACKUP, keeping the last $CT_KEEP backups per group."
printf 'Press ENTER to confirm: '; read a
# each group keeps its own CT_KEEP: local backups in the root, each volume in its subdir
for d in "$CT_BACKUP" "$CT_BACKUP"/*/; do
  ls -1t "$d"/*.tar* 2>/dev/null | tail -n +$((CT_KEEP+1)) | xargs -r rm -fv
done

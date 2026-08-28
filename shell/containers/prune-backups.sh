#!/bin/sh
set -e
. "$(dirname "$0")/env.sh"
read -p "Pruning directories while keeping last $KEEP backups in $BACKUP. Press ENTER to confirm: "
for d in $BACKUP/*;do echo "Pruning $d (keeping last $KEEP)...";rm -vf $(ls -t $d | tail -n +$DELETE | xargs -n1 echo $d/ | sed 's|/ |/|g');done
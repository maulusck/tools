#!/bin/bash
BAK_DIR="/blackbox/BAK/pod_volumes"

KEEP=${1:-9}
DELETE=$(( ${1:-9} + 1 ))

read -p "Pruning directories while keeping last $KEEP backups in $BAK_DIR. Press ENTER to confirm: "

for directory in $BAK_DIR/* ; do
        echo "Pruning $directory (keeping last $KEEP)..."
        rm -vf $( ls -t $directory | tail -n +$DELETE | xargs -n1 echo $directory/ | sed 's|/ |/|g' )
done

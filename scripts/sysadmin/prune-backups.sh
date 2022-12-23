#!/bin/bash

# Delete sorting by timestamp files in subdirectories of the specified folder.
# Useful when keeping backups organized by subfolders.
BAK_DIR=""

KEEP=${1:-9}
DELETE=$(( ${1:-9} + 1 ))

read -p "Pruning directories in $BAK_DIR (while keeping last $KEEP backups). Press ENTER to confirm, or Ctrl+C to exit: "

for directory in $BAK_DIR/* ; do
        echo "Pruning $directory (keeping last $KEEP)..."
        rm -vf $( ls -t $directory | tail -n +$DELETE | xargs -n1 echo $directory/ | sed 's|/ |/|g' )
done

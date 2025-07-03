#!/bin/sh
set -e

## env vars
MIKROTIKS="
mikrotik1
mikrotik2
mikrotik3
...
"
#
BAK_DIR="/srv/bak/mikrotik"
SSH_USER="admin"
SSH_PORT="22"
SSH_KEY="/home/.service/.ssh/id_rsa"
##

# exit if backup folder does not exist
[ -d "$BAK_DIR" ] || (echo "Backup directory '$BAK_DIR' does not exist!"; exit 1)
# exit if ssh key does not exist/is not readable
[ -r "$SSH_KEY" ] || (echo "ssh key '$SSH_KEY' does not exist/is not accessible, please check."; exit 1)

# ssh and export config to subfolder
for mikrotik in $MIKROTIKS; do
	mkdir -p $BAK_DIR/$mikrotik
	echo "ssh -p $SSH_PORT -i $SSH_KEY $SSH_USER@$mikrotik export | tee $BAK_DIR/$mikrotik/$mikrotik-export-bak-$(date -I).txt"
done

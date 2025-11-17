#!/bin/sh
set -e
. "$(dirname "$0")/env.sh"
VOLUMES=$($ct volume ls|grep -w local|awk -F " " '{print$2}')
for v in $VOLUMES;do
  echo "Backing up $v in $BACKUP/$v..."
  [ -d $BACKUP/$v ]||mkdir -p $BACKUP/$v
  $ct volume export $v >$BACKUP/$v/$v-$(date -Iminutes|sed 's|:|-|g;s|+|-|g').tar
done
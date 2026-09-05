#!/bin/sh
set -e
. "$(dirname "$0")/env.sh"
for img in $($ct images --format '{{.Repository}}:{{.Tag}}' | grep -vE '<none>|^localhost/'); do
  $ct pull "$img"
done
$ct image prune -f

#!/bin/sh
set -e
. "$(dirname "$0")/env.sh"
for v in $($ct volume ls --filter driver=local --format '{{.Name}}'); do
  echo "Backing up $v to $CT_BACKUP/$v..."
  mkdir -p "$CT_BACKUP/$v"
  $ct run --rm -v "$v":/data:ro "$CT_IMG" tar cf - -C /data . \
    >"$CT_BACKUP/$v/$v-$(date -u +%Y%m%dT%H%M%SZ).tar"
done

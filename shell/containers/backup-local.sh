#!/bin/sh
set -e
. "$(dirname "$0")/env.sh"
[ -e "$CT_LOCAL" ]
d=$(dirname "$CT_LOCAL"); b=$(basename "$CT_LOCAL")
if command -v xz >/dev/null 2>&1; then z=J e=xz; else z=z e=gz; fi
of="$CT_BACKUP/local-$(date -I).tar.$e"
if command -v tqdm >/dev/null 2>&1; then
  tar "c${z}hf" - -C "$d" "$b" | tqdm --bytes --total "$(du -sbL "$CT_LOCAL"|cut -f1)" >"$of"
else tar "c${z}hf" "$of" -C "$d" "$b"; fi

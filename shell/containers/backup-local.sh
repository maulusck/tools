#!/bin/sh
set -e
. "$(dirname "$0")/env.sh"
# rootless podman: re-exec inside its userns once, so container-written (uid-mapped) files are readable
if [ "${ct##*/}" = podman ] && [ "$(id -u)" -ne 0 ] && [ -z "${_CT_UNSHARED:-}" ]; then
  _CT_UNSHARED=1 exec "$ct" unshare "$0" "$@"
fi
[ -e "$CT_LOCAL" ]
d=$(dirname "$CT_LOCAL"); b=$(basename "$CT_LOCAL")
if command -v xz >/dev/null 2>&1; then z=J e=xz; else z=z e=gz; fi
of="$CT_BACKUP/local-$(date -u +%Y%m%dT%H%M%SZ).tar.$e"
if command -v tqdm >/dev/null 2>&1; then
  tar "c${z}hf" - -C "$d" "$b" | tqdm --bytes --total "$(du -sbL "$CT_LOCAL"|cut -f1)" >"$of"
else tar "c${z}hf" "$of" -C "$d" "$b"; fi

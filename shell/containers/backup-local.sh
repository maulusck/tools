#!/bin/sh
set -e
. "$(dirname "$0")/env.sh"
test -d ${LOCAL}||exit 1
of=${BACKUP}/local-$(date -I).tar.xz
[ -z "$(command -v tqdm)" ]&&tar cJf ${of} -C $(dirname ${LOCAL}) $(basename ${LOCAL})||(
  tar cJf - -C $(dirname ${LOCAL}) $(basename ${LOCAL})|
  tqdm --bytes --total $(du -sb ${LOCAL}|cut -f1) > ${of}
)||exit 1
exit 0
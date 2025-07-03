#!/bin/sh
set -e

LOCAL="${HOME}/local"
BAK_DIR="/srv/bak/podman/local"

# do backup
test -d ${LOCAL} || exit 1
outfile=${BAK_DIR}/$(whoami)-local-$(date -I).tar.xz

# use tqdm if available
[ -z "$(command -v tqdm)" ] \
&& (
        tar cJf ${outfile} -C $(dirname ${LOCAL}) $(basename ${LOCAL}) || exit 1
) || (
        tar cJf - -C $(dirname ${LOCAL}) $(basename ${LOCAL})\
        | tqdm --bytes --total $(du -sb ${LOCAL}|cut -f1) > ${outfile} || exit 1
)
exit 0

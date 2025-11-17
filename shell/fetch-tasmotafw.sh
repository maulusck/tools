#!/bin/sh
set -e
MIRROR_URL="http://ota.tasmota.com/tasmota/release/"
OUTDIR="${1:-./tasmota-latest-fw}"
echo "Using output directory: $OUTDIR"
wget -c -t 0 -T 15 -r -N -nd -np -e robots=off -R "index.htm*" -R "*.svg" $MIRROR_URL
echo "Downloaded to \"$OUTDIR\"."
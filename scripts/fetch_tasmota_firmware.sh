#!/bin/sh
MIRROR_URL="http://ota.tasmota.com/tasmota/release/"
exec wget -r -N -nd -np -e robots=off -R "index.htm*" -R "*.svg" $MIRROR_URL

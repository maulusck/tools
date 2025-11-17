#!/bin/sh
set -e
. "$(dirname "$0")/env.sh"
for img in $($ct images --noheading | grep -vE '<none>|localhost' | awk '{print $1 ":" $2}');do $ct pull $img;done
$ct image prune -f
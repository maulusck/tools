#!/bin/sh
set -e
. "$(dirname "$0")/env.sh"
$ct rm -f $($ct ps -aq) 2>/dev/null || true
$ct image prune -f

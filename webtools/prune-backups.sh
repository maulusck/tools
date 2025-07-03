#!/bin/sh

set -e
# prune history
bak_dir=/backup/history
websites=$(ls $bak_dir)

for website in $websites; do
	for i in $(ls $bak_dir/$website | head -n -5); do
		rm -v $bak_dir/$website/$i
	done
done

#!/bin/bash

set -e
bak_dir=/backup/DAILY
websites=$(ls $bak_dir)
webroot=/var/www
curdate=$(date -Iseconds | cut -c 1-19 | sed -e 's/:/-/g')

for website in $websites; do
	tar cvzf $bak_dir/$website/web-bak-${curdate}-DAILY.tgz $webroot/$website
done

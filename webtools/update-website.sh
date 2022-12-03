#!/bin/bash

# quit on error
set -e
# need args
if [ -z $1 ]; then
	echo "Provide website as argument."
else
# user vars
website=$1
user=$( \
	for site in $(ls /home/); do
	if [ ! -z $(cat /home/$site/.sites | grep -w $website) ]; then
	echo $site
	fi
	done )
# script vars
if [ -z $user ]; then
	echo "Site looks unmanaged or not existing. Please configure ~/<user>/.sites . "
exit 1; fi
localsite=/home/$user/web
webroot=/var/www/$website/htdocs
backup=/backup/history/$website
curdate=$(date -Iseconds | cut -c 1-19 | sed -e 's/:/-/g')
# file check
for dir in $webroot $localsite; do
	if [ ! -d $dir ]; then
	echo "$dir is not a valid path!"
	exit 1;	fi
done
# exec
tar cvzf $backup/web-bak-${curdate}.tgz $webroot/
rsync -vr --progress --delete-after $localsite/ $webroot/
# fix permissions
for i in $(find $webroot -type f ); do (chmod 644 $i) done
for i in $(find $webroot -type d ); do (chmod 755 $i) done
# done
rc-service apache2 restart
echo "Done!"
fi

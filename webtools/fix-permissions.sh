#!/bin/sh

if [ -z $1 ]; then
	echo "Provide folder as argument."
else
	find $1 -type f -exec chmod 644 {} \;
	find $1 -type d -exec chmod 755 {} \;
fi

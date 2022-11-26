#!/bin/sh

INSTALL_DIR="/usr/share/fonts/opentype"
TEMP_DIR="tmp"
FONTS="\
https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg \
https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg \
https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg \
https://devimages-cdn.apple.com/design/resources/download/SF-Arabic.dmg \
https://devimages-cdn.apple.com/design/resources/download/NY.dmg \
"

# make dir
mkdir -p ./$TEMP_DIR && cd ./$TEMP_DIR

# download
wget -c -t 0 -T 15 $FONTS

# extract
for f in *.dmg; do (7z x ./$f) done
for d in $(find . -maxdepth 1 -type d) ; do

#	[ "$d" != "." ] && bash -c "cd $d && 7z x ./*.pkg && exit 0"
#	[ "$d" != "." ] && bash -c "cd $d && 7z x ./Payload* && exit 0"
#	[ "$d" != "." ] && bash -c "cd $d && mkdir -p $d && mv ./Library/Fonts/* ./$d && exit 0"

# install
	[ "$d" != "." ] && bash -c "cd $d && sudo cp -rfv ./$d $INSTALL_DIR/ && \
								find $INSTALL_DIR/$d -exec chown -R root:root {} \; \
								find $INSTALL_DIR/$d -type d -exec chmod 755 {} \; \
								find $INSTALL_DIR/$d -type f -exec chmod 644 {} \; \
								exit 0"
# done
done
fc-cache -f -v

# cleanup
cd ..
rm -rfv ./$TEMP_DIR

# done
echo "Done."

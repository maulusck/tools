#!/bin/sh
set -e
# vars
OUTDIR="${1:-$HOME/apple-fonts}"
echo "Using output directory: $OUTDIR"
FONT_URLS="\
https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg \
https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg \
https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg \
https://devimages-cdn.apple.com/design/resources/download/SF-Arabic.dmg \
https://devimages-cdn.apple.com/design/resources/download/NY.dmg \
"
# make dir
_tmpdir="$(uuidgen)"
mkdir -p "$OUTDIR/$_tmpdir"
cd "$OUTDIR/$_tmpdir"
# download
wget -c -t 0 -T 15 $FONT_URLS
# extract
for f in *.dmg; do (7z x ./$f) done
for d in $(find . -maxdepth 1 -type d) ; do
	[ "$d" != "." ] && bash -c "cd $d && 7z x ./*.pkg && exit 0"
	[ "$d" != "." ] && bash -c "cd $d && 7z x ./Payload* && exit 0"
	[ "$d" != "." ] && bash -c "cd $d && mkdir -p $d && mv ./Library/Fonts/* ./$d && exit 0"
# install
	[ "$d" != "." ] && bash -c "cd $d && mv -v \"$d\" \"$OUTDIR/\""
# done
done
# cleanup
cd "$OUTDIR"
rm -rf "$OUTDIR/$_tmpdir"
# done
echo "Downloaded to \"$OUTDIR\"."
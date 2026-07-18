#!/bin/sh
# gdm-bg.sh -- set the GDM (GNOME Shell) login/lock background image.
# Idempotent: re-runnable, always rebuilds from the pristine theme.

set -eu

usage() {
	cat >&2 <<EOF
usage: $0 [-r] IMAGE   set background (-r also restarts gdm)
       $0 -R [-r]      revert to the saved original
       $0 -c           self-check (no root, touches nothing)
EOF
	exit 2
}

gst=/usr/share/gnome-shell/gnome-shell-theme.gresource
orig=${gst%.gresource}-original.gresource
prefix=/org/gnome/shell/theme

# manifest: read gresource entries on stdin, emit the .gresource.xml with
# the extra image appended. Pure transform -- the bit worth self-checking.
manifest() {
	echo '<?xml version="1.0" encoding="UTF-8"?>'
	echo '<gresources>'
	printf '  <gresource prefix="%s">\n' "$prefix"
	while read -r r; do
		printf '    <file>%s</file>\n' "${r#"$prefix/"}"
	done
	[ -n "${1:-}" ] && printf '    <file>%s</file>\n' "$1"
	echo '  </gresource>'
	echo '</gresources>'
}

selftest() {
	list="$prefix/gnome-shell-dark.css
$prefix/pad-osd.css"
	a=$(printf '%s\n' "$list" | manifest bg.png)
	b=$(printf '%s\n' "$list" | manifest bg.png)
	[ "$a" = "$b" ]                                   || { echo "FAIL: not deterministic"; exit 1; }
	[ "$(printf '%s' "$a" | grep -c '<file>bg.png')" -eq 1 ] || { echo "FAIL: image not injected once"; exit 1; }
	printf '%s' "$a" | grep -q '<file>gnome-shell-dark.css</file>' || { echo "FAIL: prefix strip"; exit 1; }
	echo "ok"
}

restart=0; revert=0
while getopts rRc opt; do
	case $opt in
	r) restart=1 ;;
	R) revert=1 ;;
	c) selftest; exit 0 ;;
	*) usage ;;
	esac
done
shift $((OPTIND - 1))

if [ "$revert" -eq 1 ]; then
	[ "$(id -u)" -eq 0 ] || { echo "$0: run as root" >&2; exit 1; }
	[ -f "$orig" ]       || { echo "$0: no saved original at $orig" >&2; exit 1; }
	cp "$orig" "$gst"
	echo "$0: reverted to original"
	[ "$restart" -eq 1 ] && { echo "$0: restarting gdm"; systemctl restart gdm 2>/dev/null || systemctl restart gdm3; }
	exit 0
fi

[ $# -eq 1 ]         || usage
img=$1
[ -f "$img" ]        || { echo "$0: no such file: $img" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "$0: run as root" >&2; exit 1; }
command -v gresource >/dev/null              || { echo "$0: gresource missing" >&2; exit 1; }
command -v glib-compile-resources >/dev/null || { echo "$0: glib-compile-resources missing" >&2; exit 1; }

# Keep one pristine copy; always work from it so re-runs never stack patches.
[ -f "$orig" ] || cp "$gst" "$orig"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Extract the pristine theme (every entry shares the theme prefix).
for r in $(gresource list "$orig"); do
	rel=${r#"$prefix/"}
	case $rel in */*) mkdir -p "$work/${rel%/*}" ;; esac
	gresource extract "$orig" "$r" > "$work/$rel"
done

base=$(basename "$img")
cp "$img" "$work/$base"

# Regenerate the manifest from the live file list + our image (version-proof).
gresource list "$orig" | manifest "$base" > "$work/gnome-shell-theme.gresource.xml"

# Override #lockDialogGroup by appending -- last rule of equal specificity wins.
# ponytail: background-size:cover, swap to explicit "WIDTHpx HEIGHTpx" if you
# need pixel-exact scaling for GDM's resolution.
for css in "$work"/gnome-shell*.css; do
	[ -f "$css" ] || continue
	cat >> "$css" <<EOF
#lockDialogGroup {
  background: url("$base");
  background-size: cover;
  background-repeat: no-repeat;
}
EOF
done

( cd "$work" && glib-compile-resources gnome-shell-theme.gresource.xml )
cp "$work/gnome-shell-theme.gresource" "$gst"
echo "$0: background set to $base"

[ "$restart" -eq 1 ] && { echo "$0: restarting gdm"; systemctl restart gdm 2>/dev/null || systemctl restart gdm3; }
exit 0

wget --recursive \ #${comment# self-explanatory}
 --no-parent \ #${comment# will not crawl links in folders above the base of the URL}
 --convert-links \ #${comment# convert links with the domain name to relative and uncrawled to absolute}
 --random-wait --wait 3 --no-http-keep-alive \ #${comment# do not get banned}
 --no-host-directories \ #${comment# do not create folders with the domain name}
 --execute robots=off --user-agent=Mozilla/5.0 \ #${comment# I AM A HUMAN!!!}
 --level=inf  --accept '*' \ #${comment# do not limit to 5 levels or common file formats}
 --reject="index.html*" \ #${comment# use this option if you need an exact mirror}
 --cut-dirs=0 \ #${comment# replace 0 with the number of folders in the path, 0 for the whole domain}

$1


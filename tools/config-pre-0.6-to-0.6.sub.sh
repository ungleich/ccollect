#!/bin/sh
# Nico Schottelius, 20070816-2227
# Transfer configuration to 0.6 layout (subscript)
# Copying: GPLv3
#

if [ $# -ne 1 ]; then
   echo "$0: rsync_options file"
   echo ""
   echo "   Fix pre 0.6 configuration directories to match 0.6 style (sub)"
   echo ""
   exit 23
fi

tmp=$(mktemp)

echo "Working on $1 ..."

for option in $(cat "$1"); do
   echo "${option}" >> "${tmp}"
done
mv ${tmp} "$1"

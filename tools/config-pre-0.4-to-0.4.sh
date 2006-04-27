#!/bin/sh
# Nico Schottelius
# Do Apr 27 09:13:26 CEST 2006
#

if [ $# -ne 1 ]; then
   echo "$0: ccollect-configuration directory"
   echo ""
   echo "   Fix pre 0.4 configuration directories to match 0.4 style"
   echo ""
   exit 23
fi

tmp=$(mktemp)
tmp2=$(mktemp)
script=$(echo $0 | sed 's/\.sh/.sub.sh/')

find "$1" -type d -name intervalls > "$tmp"

#
# reverse found data, so deepest directories are renamed first
#
tac "$tmp" > "$tmp2"

while read intervals
   do
   "$script" "$intervals"
done < "$tmp2"

rm -f "$tmp" "$tmp2"

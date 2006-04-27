#!/bin/sh
# Nico Schottelius
# Do Apr 27 09:13:26 CEST 2006
#

master=$(echo $0 | sed 's/\.sub//')

if [ $# -ne 1 ]; then
   echo "$0:"
   echo ""
   echo "   DO NOT CALL ME DIRECTLY"
   echo ""
   echo "Use $master, please."
   exit 23
fi

# strip trailing /
oldname=$(echo $1 | sed 's,/$,,')

# replace the last component of the path "intervalls"
newname=$(echo $oldname | sed 's/intervalls$/intervals/')

echo mv "$oldname" "$newname"
mv "$oldname" "$newname"

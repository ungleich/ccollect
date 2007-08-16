#!/bin/sh
# Nico Schottelius, 20070816-2225
# Transfer configuration to 0.6 layout
# Copying: GPLv3
#

if [ $# -ne 1 ]; then
   echo "$0: ccollect-configuration directory"
   echo ""
   echo "   Fix pre 0.6 configuration directories to match 0.6 style"
   echo ""
   exit 23
fi

dir="$1"
script=$(echo $0 | sed 's/\.sh$/.sub.sh/')

find "${dir}/sources/" -type f -name rsync_options -exec "${script}" {} \;

echo "Finished."

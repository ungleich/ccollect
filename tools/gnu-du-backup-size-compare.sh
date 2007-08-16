#!/bin/sh
#
# Nico Schottelius <nico-ccollect //@// schottelius.org>
# Date: 2007-08-16
# Last Modified: -
#

exit 1
# not yet finished.

CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
CCOLLECT_SOURCES="$CCOLLECT_CONF/defaults/sources"

me="$(basename "$0")"

if [ $# -lt 1 ]; then
   echo "${me}: sources names
   exit 1
fi

if [ ! -d "$CCOLLECT_SOURCES" ]; then
   echo "No sources defined in $CCOLLECT_SOURCES"
   exit 1
fi

cd "$CCOLLECT_INTERVALS"

for interval in *; do
   eval int_$interval=$(cat $interval);
   eval echo $interval: \$int_$interval;
done

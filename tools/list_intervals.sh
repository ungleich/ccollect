#!/bin/sh
#
# Nico Schottelius <nico-linux //@// schottelius.org>
# Date: 24-Jun-2006
# Last Modified: -
#

CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
CCOLLECT_INTERVALS="$CCOLLECT_CONF/defaults/intervals"

if [ ! -d "$CCOLLECT_INTERVALS" ]; then
   echo "No intervals defined in $CCOLLECT_INTERVALS"
   exit 23
fi

cd "$CCOLLECT_INTERVALS"

for interval in *; do
   eval int_$interval=$(cat $interval);
   eval echo $interval: \$int_$interval;
done

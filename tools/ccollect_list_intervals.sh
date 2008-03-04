#!/bin/sh
#
# Nico Schottelius <nico-ccollect //@// schottelius.org>
# Date: 24-Jun-2006
# Last Modified: -
# Copying: GPLv3 (See file COPYING in top directory)
#

CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
CCOLLECT_INTERVALS="$CCOLLECT_CONF/defaults/intervals"

me="$(basename $0)"

_echo()
{
   echo "$me> $@"
}

if [ ! -d "${CCOLLECT_INTERVALS}" ]; then
   _echo "No intervals defined in ${CCOLLECT_INTERVALS}"
   exit 1
fi

set -e
cd "${CCOLLECT_INTERVALS}"

for interval in *; do
   eval int_${interval}=$(cat "${interval}");
   eval echo ${interval}: \$int_${interval};
done

#!/bin/sh
# 
# 2006-2008 Nico Schottelius (nico-ccollect at schottelius.org)
# 
# This file is part of ccollect.
#
# ccollect is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ccollect is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with ccollect. If not, see <http://www.gnu.org/licenses/>.
#
# Initially written on 24-Jun-2006
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

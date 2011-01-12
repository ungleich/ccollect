#!/bin/sh
# 
# 2007-2008 Nico Schottelius (nico-ccollect at schottelius.org)
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
# Written on 2007-08-16
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

cd "${CCOLLECT_SOURCES}"

while [ "$#" -gt 0 ]; do
   source="$1"; shift
   fsource="${CCOLLECT_SOURCES}/${source}"
   du -s "${fsource}/"* "${fsource}"
   # du -l should follow
done

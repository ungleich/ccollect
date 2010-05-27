#!/bin/sh
# 
# 2009 Nico Schottelius (nico-ccollect at schottelius.org)
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
# Write a tar containing the configuration
#

# standard values
CCOLLECT_CONF="${CCOLLECT_CONF:-/etc/ccollect}"

self="$(basename $0)"

# functions first
_echo()
{
   echo "${self}> $@"
}

_exit_err()
{
   _echo "$@"
   rm -f "$TMP"
   exit 1
}

# argv
if [ $# -ne 1 ]; then
   _echo "${self} <archivename>"
   _exit_err "Exiting."
fi

file="$1"

_echo "Creating $file ..."

[ -d "${CCOLLECT_CONF}" ] || _exit_err "No configuration in $CCOLLECT_CONF"

tar cf "$file" "${CCOLLECT_CONF}"

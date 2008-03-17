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
# Written on 20070816-2227
# Transfer configuration to 0.6 layout (subscript)
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

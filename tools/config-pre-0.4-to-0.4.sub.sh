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
# Written on Do Apr 27 09:13:26 CEST 2006
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

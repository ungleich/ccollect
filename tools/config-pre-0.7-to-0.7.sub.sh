#!/bin/sh
# 
# 2008      Nico Schottelius (nico-ccollect at schottelius.org)
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
# Helper script
# 

if [ $# -ne 1 ]; then
   echo "$0: destination-file"
   echo ""
   echo "   Fix pre 0.7 configuration directories to match 0.6 style (sub)"
   echo ""
   exit 23
fi

tmp=$(mktemp)
file="$1"

echo "Working on $file ..."

if [ -L "${file}" ]; then
   echo "Converting ${file} ..."
   dir="$(cd "${file}" && pwd)"; ret=$?

   if [ $ret -ne 0 ]; then
      echo "ERROR: $file is a broken link"
      exit 1
   else
      echo "${dir}" > "${tmp}"
      rm -f "${file}";  ret=$?
      if [ $ret -ne 0 ]; then
         echo "ERROR: Removing $file failed"
         exit 1
      fi
      mv "${tmp}" "${file}"; ret=$?
      if [ $ret -ne 0 ]; then
         echo "ERROR: Moving ${tmp} to ${file} failed, your source is broken."
         exit 1
      fi
   fi
else
   echo "$file is not a link, not converting"
   exit 1
fi

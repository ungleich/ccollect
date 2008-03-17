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
# 2007-08-16 Written for Netstream (www.netstream.ch)
# Delete sources and their backups (optionally).
#

# standard values
CCOLLECT_CONF="${CCOLLECT_CONF:-/etc/ccollect}"
CSOURCES="${CCOLLECT_CONF}/sources"

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
if [ $# -lt 1 ]; then
   _echo "${self} [-f] [-d] <sources to delete>"
   _echo "  -f: Do not ask, simply delete. Dangerous and good for sysadmins."
   _echo "  -d: Also delete the destination (removes all backups)"
   _exit_err "Exiting."
fi

params_possible=yes
force=""
backups=""

while [ $# -gt 0 ]; do
   if [ "$params_possible" ]; then
      case "$1" in
         "-f"|"--force")
            force="-r"
            shift; continue
            ;;
         "-d"|"--destination")
            backups=yes
            shift; continue
            ;;
         --)
            params_possible=""
            shift; continue
            ;;
         -*|--*)
            _exit_err "Unknown option: $1" 
            ;;
      esac

   fi

   # Reached here? So there are no more parameters.
   params_possible=""

   source="$1"; shift

   # Create
   _echo "Deleting ${source} ..."
   fullname="${CSOURCES}/${source}"

   # ask the user per source, if she's not forcing us
   if [ -z "$force" ]; then
      sure=""
      echo -n "Do you really want to delete ${source} (y/n)? "
      read sure
      
      if [ "$sure" != "y" ]; then
         _echo "Skipping ${source}."
         continue
      fi
   fi

   if [ "$backups" ]; then
      ddir="$(cat "${fullname}/destination")"
      addir="$(cd && pwd -P)" || _exit_err "Cannot change to ${ddir}"
      _echo "Deleting ${addir} ..."
      rm -r $force "${addir}"
   fi

   _echo "Deleting ${fullname} ..."
   rm -r $force "${fullname}"
done

exit 0

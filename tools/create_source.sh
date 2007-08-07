#!/bin/sh
# Nico Schottelius
# 2007-08-07
# Written for Netstream (www.netstream.ch)
# Creates a source, including exclude

# standard values
CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
CSOURCES=$CCOLLECT_CONF/sources
CDEFAULTS=$CCOLLECT_CONF/defaults

self=$(basename $0)

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
if [ $# -ne 3 ]; then
   _echo "<name of the ccollect-source> <servername> <destination>"
   _echo "Example: \"my-notebook\" \"192.168.42.42\" \"/home/server/backup/my-notebook\""
   exit 1
fi

name="$1"
source="$2"
destination="$3"
fullname="${CSOURCES}/${name}"

# Tests
if [ -e "${fullname}" ]; then
   _echo "${fullname} already exists. Aborting."
   exit 2
fi

_echo "Trying to reach ${source} ..."
ping -c1 "${source}" || _exit_err "Cannot reach ${source}. Aborting."

# Create
_echo "Creating ${fullname} ..."
mkdir -p "${fullname}" || exit 3

echo "root@${source}:/" > "${fullname}/source"
cat << eof > "${fullname}/exclude" || exit 4
/dev/*
/proc/*
/tmp/*
eof

# Destination
if [ -e "${destination}" ]; then
   if [ ! -d "${destination}" ]; then
      echo "${destination} exists, but is not a directory. Aborting."
      exit 5
   fi
else
   _echo "Creating ${destination} ..."
   mkdir -p "${destination}" || _exit_err "Failed to create ${destination}."
fi

ln -s "${destination}" "${fullname}/destination" || \
   _exit_err "Failed to link \"${destination}\" to \"${fullname}/destination\""

# finish
_echo "Added some default values, please verify \"${fullname}\"."
_echo "Finished."

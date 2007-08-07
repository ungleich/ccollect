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
   exit 1
}

_exit_err()
{
   _echo "$@"
   rm -f "$TMP"
   exit 1
}

# argv
if [ $# -ne 2 ]; then
   _echo "Arguments needed: <name of the server> <where to store backup>"
   exit 1
fi

name="$1"
fullname="${CSOURCES}/${name}"
destination="$2"

# Tests
if [ -e "${fullname}" ]; then
   _echo "${fullname} already exists. Aborting."
   exit 2
fi

_echo "Trying to reach ${name} ..."
ping -c1 "${name}" || _exit_err "Cannot reach ${name}. Aborting."

# Create
_echo "Creating ${fullname} ..."
mkdir -p "${fullname}" || exit 3

echo "${name}:/" > "${fullname}/source"
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
   mkdir -p "${destination}" || _exit_err "Failed to create ${destination}."
fi

ln -s "${destination}" "${fullname}/destination" || \
   _exit_err "Failed to link \"${destination}\" to \"${fullname}/destination\""

# finish
_echo "Added some default values, please verify ${fullname}."
_echo "Finished."

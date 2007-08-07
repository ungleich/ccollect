#!/bin/sh
# Nico Schottelius
# 2007-08-07
# Written for Netstream (www.netstream.ch)
# Creates a source, including exclude

# standard values
CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
CSOURCES=$CCOLLECT_CONF/sources
CDEFAULTS=$CCOLLECT_CONF/defaults

# functions first
_echo()
{
   echo -n "$(basename $0)> $@"
   exit 1
}

_exit_err()
{
   _echo "$@"
   rm -f "$TMP"
   exit 1
}

# argv
if [ $# -ne 1 ]; then
   _echo "$(basename $0): <name of the server>"
   exit 1
fi

name="$1"
fullname="${CSOURCES}/${name}"

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
cat << eof > "${fullname}/exclude"
/dev/*
/proc/*
/tmp/*
eof

# finish
_echo "Added some default values, please verify ${fullname}."
_echo "Finished."

#!/bin/sh
# Nico Schottelius
# 2007-08-07
# Written for Netstream (www.netstream.ch)
# Creates a source, including exclude

if [ $# -ne 1 ]; then
   echo $(basename $0): name
   exit 1
fi

CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
CSOURCES=$CCOLLECT_CONF/sources
CDEFAULTS=$CCOLLECT_CONF/defaults

name="$1"
fullname="${CSOURCES}/${name}"

if [ -e "${fullname}" ]; then
   echo "${fullname} already exists. Aborting."
   exit 2
fi

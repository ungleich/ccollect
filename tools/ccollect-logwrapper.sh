#!/bin/sh
# Nico Schottelius
# written for Netstream (www.netstream.ch)
# Date: Fr 8. Jun 10:30:24 CEST 2007
# Call the log-wrapper instead of ccollect.sh and it will log
# to your selected destinations

# not implemented
exit 0

Analyses output produced by ccollect.

#
# where to find our configuration and temporary file
#
CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
LOGCONF=$CCOLLECT_CONF/logwrapper
VERSION=0.1
RELEASE="2007-XX-XX"

HALF_VERSION="ccollect $VERSION"
FULL_VERSION="ccollect $VERSION ($RELEASE)"

# syslog: logger -t ccollect-logwrapper


#!/bin/sh
# Nico Schottelius
# written for Netstream (www.netstream.ch)
# Date: Fr 8. Jun 10:30:24 CEST 2007
# Call the log-wrapper instead of ccollect.sh and it will create nice logs

#
# where to find our configuration and temporary file
#
CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
LOGCONF=$CCOLLECT_CONF/logwrapper

logdir="${LOGCONF}/destination"
CDATE="date +%Y%m%d-%H%M"
we="$(basename $0)"
pid=$$

logfile="${logdir}/$(${CDATE}).${pid}"

# use syslog normally
# Also use echo, can be redirected with > /dev/null if someone cares
_echo()
{
   string="${we} (${pid}): $@"
   logger "${string}"
   echo "${string}"
}


# exit on error
_exit_err()
{
   _echo "$@"
   rm -f "${TMP}"
   exit 1
}

# put everything into that specified file
_echo "Starting with arguments: $@"
touch "${logfile}" || _exit_err "Failed to create ${logfile}"

# First line in the logfile is always the commandline
echo ccollect.sh "$@" > "${logfile}" 2>&1
ccollect.sh "$@" >> "${logfile}" 2>&1

_echo "Finished."

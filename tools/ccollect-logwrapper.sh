#!/bin/sh
# Nico Schottelius
# written for Netstream (www.netstream.ch)
# Date: Fr 8. Jun 10:30:24 CEST 2007
# Call the log-wrapper instead of ccollect.sh and it will create nice logs

Analyses output produced by ccollect.

#
# where to find our configuration and temporary file
#
CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
LOGCONF=$CCOLLECT_CONF/logwrapper

logdir="${LOGCONF}/destination"
CDATE="date +%Y%m%d-%H%M"
we="$(basenae $0)"
pid=$$

logfile="${logdir}/$(${CDATE}).${pid}"

# use syslog normally
_echo()
{
   logger "${we}-${pid}: $@"
   echo "${we}-${pid}: $@"
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
ccollect.sh "$@" > "${logfile}" 2>&1
_echo "Finished."

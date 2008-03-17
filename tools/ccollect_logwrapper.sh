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
# Written for Netstream (www.netstream.ch) on  Fr 8. Jun 10:30:24 CEST 2007
#
# Call the log-wrapper instead of ccollect.sh and it will create nice logs
#

#
# where to find our configuration and temporary file
#
CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
LOGCONF=$CCOLLECT_CONF/logwrapper

logdir="${LOGCONF}/destination"
CDATE="date +%Y%m%d-%H%M"
we="$(basename $0)"
pid=$$

export ccollect_logfile="${logdir}/$(${CDATE}).${pid}"

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
   _echo "$@" >&2
   rm -f "${TMP}"
   exit 1
}

# put everything into that specified file
_echo "Starting with arguments: $@"
touch "${ccollect_logfile}" || _exit_err "Failed to create ${ccollect_logfile}"

# First line in the logfile is always the commandline
echo ccollect.sh "$@" > "${ccollect_logfile}" 2>&1
ccollect.sh "$@" >> "${ccollect_logfile}" 2>&1

_echo "Finished."

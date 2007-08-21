#!/bin/sh
# Nico Schottelius
# written for Netstream (www.netstream.ch)
# Date: Di 21. Aug 17:10:15 CEST 2007
# Analyse existing logs

# Interesting strings in the logs:
# --------------------------------------------------------
# err
# [ddba017.netstream.ch] receiving file list ... cannot send long-named file "/usr/local/www/apache22/cgi-bin/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/ backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/bac kup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup /backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/ba ckup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backu p/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/back"
#[ddba033.netstream.ch] rsync: readlink "/usr/local/inetpub2/webmailroot/2wire.ch/royal@2wire.ch" failed: Input/output error (5)
#[ddba033.netstream.ch] WARNING: usr/local/inetpub2/netstream/adsl.netstream.ch/mrtg/lbswiss.rrd failed verification -- update discarded (will try again).
#[ddba033.netstream.ch] rsync: read errors mapping "/usr/local/inetpub2/netstream/adsl.netstream.ch/mrtg/lbswiss.rrd": Input/output error (5)
#[ddba033.netstream.ch] ERROR: usr/local/inetpub2/netstream/adsl.netstream.ch/mrtg/lbswiss.rrd failed verification -- update discarded.
#[ddba033.netstream.ch] rsync: read errors mapping "/usr/local/inetpub2/netstream/adsl.netstream.ch/mrtg/lbswiss.rrd": Input/output error (5)
#[ddba049.netstream.ch] receiving file list ... rsync: readdir("/proc"): Invalid argument (22)
#[zrha165.netstream.ch] Read from remote host zrha165.netstream.ch: Connection reset by peer
#[zrha165.netstream.ch] rsync: connection unexpectedly closed (10722819 bytes received so far) [receiver]
#[zrha165.netstream.ch] rsync error: error in rsync protocol data stream (code 12) at io.c(453) [receiver=2.6.9]
#[zrha165.netstream.ch] rsync: connection unexpectedly closed (10710627 bytes received so far) [generator]
#[zrha165.netstream.ch] rsync error: unexplained error (code 255) at io.c(453) [generator=2.6.9]
#[zrha165.netstream.ch] 2007-08-21-03:32:04: Finished backup (rsync return code: 255).
#[zrha166.netstream.ch] Read from remote host zrha166.netstream.ch: Connection reset by peer
#[zrha166.netstream.ch] rsync: connection unexpectedly closed (12731672 bytes received so far) [receiver]
#[zrha166.netstream.ch] rsync error: error in rsync protocol data stream (code 12) at io.c(453) [receiver=2.6.9]
#[zrha166.netstream.ch] rsync: connection unexpectedly closed (12721988 bytes received so far) [generator]
#[zrha166.netstream.ch] rsync error: unexplained error (code 255) at io.c(453) [generator=2.6.9]
#[zrha166.netstream.ch] 2007-08-21-03:12:15: Finished backup (rsync return code: 255).
# Read from remote host .*: Connection timed out
# rsync: mknod .* failed: Invalid argument (22)

# warn
# [ddba015.netstream.ch] send_files failed to open /usr/local/dnscache/log/main/@4000000046ca0f3616939c14.s: No such file or directory
# [ddba015.netstream.ch] 2007-08-21-02:17:28: Finished backup (rsync return code: 23).
# [ddba017.netstream.ch] file has vanished: "/var/spool/postfix/active/657575D686"
#[ddba026.netstream.ch] 2007-08-21-05:35:13: Finished backup (rsync return code: 24).
#[ddba045.netstream.ch] send_files failed to open /data/hsphere/local/var/named/logs/@4000000046c98fa9079f39ac.s: No such file or directory
# file has vanished: ".*"

# info:
# [u0160.nshq.ch.netstream.com] Total file size: 1694612169 bytes
# [u0160.nshq.ch.netstream.com] Total transferred file size: 17997414 bytes
# [u0160.nshq.ch.netstream.com] 2007-08-20-18:26:06: Backup lasted: 0:43:34 (h:m:s)
#[ddba012.netstream.ch] sent 3303866 bytes  received 1624630525 bytes  122700.92 bytes/sec
#[ddba012.netstream.ch] total size is 22384627486  speedup is 13.75
#[ddba012.netstream.ch] 2007-08-21-04:03:21: Finished backup (rsync return code: 0).
# speedup is
# error codes




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

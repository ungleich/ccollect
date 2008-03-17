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
# Written for Netstream (www.netstream.ch) on Di 21. Aug 17:10:15 CEST 2007
#
# Analyse logs
#

version=0.1
date=2007-08-24
fullversion="${version} (${date})"
args=iwe

usage() {
   echo "$(basename "$0") ${fullversion}: [iwe]"
   echo ""
   echo "   i: print informational messages"
   echo "   w: print warning       messages"
   echo "   e: print error         messages"
   echo ""
   echo "Reading input from stdin, displaying to stdout."
   exit 1
}

#
# read and verify argv
#
if [ "$#" -ne 1 ]; then
   usage
fi
argv="$1"; shift

wrong="$(echo ${argv} | grep -e "[^${args}]")"
if [ "${wrong}" ]; then
   usage
fi


# set output levels
search_err="$(echo  ${argv} | grep 'e')"
search_warn="$(echo ${argv} | grep 'w')"
search_info="$(echo ${argv} | grep 'i')"

#
# Interesting strings in the logs: errors
# ---------------------------------------

if [ "$search_err" ]; then
   set -- "$@" "-e" 'Read from remote host .*: Connection timed out$'
   set -- "$@" "-e" 'Read from remote host .*: Connection reset by peer$'
   set -- "$@" "-e" 'rsync: .*: Invalid argument (22)$'
   set -- "$@" "-e" 'rsync: .*: Input/output error (5)$'
   set -- "$@" "-e" 'cannot send long-named file "'
   set -- "$@" "-e" 'ERROR: .* failed verification -- update discarded.$'
fi

# known error strings:
#[ddba049.netstream.ch] receiving file list ... rsync: readdir("/proc"): Invalid argument (22)
#[ddba033.netstream.ch] rsync: readlink "/usr/local/inetpub2/webmailroot/2wire.ch/royal@2wire.ch" failed: Input/output error (5)
#[ddba033.netstream.ch] rsync: read errors mapping "/usr/local/inetpub2/netstream/adsl.netstream.ch/mrtg/lbswiss.rrd": Input/output error (5)
#[zrha165.netstream.ch] Read from remote host zrha165.netstream.ch: Connection reset by peer
#[ddba017.netstream.ch] receiving file list ... cannot send long-named file "/usr/local/www/apache22/cgi-bin/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/ backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/bac kup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup /backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/ba ckup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backu p/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/backup/back"
#[ddba033.netstream.ch] ERROR: usr/local/inetpub2/netstream/adsl.netstream.ch/mrtg/lbswiss.rrd failed verification -- update discarded.


#
# Interesting strings in the logs: warnings
# -----------------------------------------
#[ddba033.netstream.ch] rsync: read errors mapping "/usr/local/inetpub2/netstream/adsl.netstream.ch/mrtg/lbswiss.rrd": Input/output error (5)

# [ddba015.netstream.ch] send_files failed to open /usr/local/dnscache/log/main/@4000000046ca0f3616939c14.s: No such file or directory
# [ddba015.netstream.ch] 2007-08-21-02:17:28: Finished backup (rsync return code: 23).
# [ddba017.netstream.ch] file has vanished: "/var/spool/postfix/active/657575D686"
#[ddba026.netstream.ch] 2007-08-21-05:35:13: Finished backup (rsync return code: 24).
#[ddba045.netstream.ch] send_files failed to open /data/hsphere/local/var/named/logs/@4000000046c98fa9079f39ac.s: No such file or directory
# file has vanished: ".*"

if [ "$search_warn" ]; then
   # warn on non-zero exit code
   set -- "$@" "-e" 'Finished backup (rsync return code: [^0]'
   set -- "$@" "-e" 'WARNING: .* failed verification -- update discarded (will try again).'
fi
# known warnings:
#[ddba033.netstream.ch] WARNING: usr/local/inetpub2/netstream/adsl.netstream.ch/mrtg/lbswiss.rrd failed verification -- update discarded (will try again).


#
# Interesting strings in the logs: informational
# ----------------------------------------------
if [ "$search_info" ]; then
   set -- "$@" "-e" 'total size is [[:digit:]]*  speedup is'
   set -- "$@" "-e" 'Backup lasted: [[:digit:]]*:[[:digit:]]\{1,2\}:[[:digit:]]* (h:m:s)$'
   set -- "$@" "-e" 'send [[:digit:]]* bytes  received [0-9]* bytes  [0-9]* bytes/sec$'
fi

# info includes:
#[ddba012.netstream.ch] total size is 22384627486  speedup is 13.75
# [u0160.nshq.ch.netstream.com] 2007-08-20-18:26:06: Backup lasted: 0:43:34 (h:m:s)
#[ddba012.netstream.ch] sent 3303866 bytes  received 1624630525 bytes  122700.92 bytes/sec

grep "$@"

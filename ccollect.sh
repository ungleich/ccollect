#!/bin/sh
#
# 2005-2009 Nico Schottelius (nico-ccollect at schottelius.org)
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
# Initially written for SyGroup (www.sygroup.ch)
# Date: Mon Nov 14 11:45:11 CET 2005

# Error upon expanding unset variables:
set -u

#
# Standard variables (stolen from cconf)
#
__pwd="$(pwd -P)"
__mydir="${0%/*}"; __abs_mydir="$(cd "$__mydir" && pwd -P)"
__myname=${0##*/}; __abs_myname="$__abs_mydir/$__myname"

#
# where to find our configuration and temporary file
#
CCOLLECT_CONF="${CCOLLECT_CONF:-/etc/ccollect}"
CSOURCES="${CCOLLECT_CONF}/sources"
CDEFAULTS="${CCOLLECT_CONF}/defaults"
CPREEXEC="${CDEFAULTS}/pre_exec"
CPOSTEXEC="${CDEFAULTS}/post_exec"

export TMP=$(mktemp "/tmp/${__myname}.XXXXXX")
VERSION="0.8"
RELEASE="2009-08-20"
HALF_VERSION="ccollect ${VERSION}"
FULL_VERSION="ccollect ${VERSION} (${RELEASE})"

#
# CDATE: how we use it for naming of the archives
# DDATE: how the user should see it in our output (DISPLAY)
#
CDATE="date +%Y%m%d-%H%M"
DDATE="date +%Y-%m-%d-%H:%M:%S"
SDATE="date +%s"

#
# unset values
#
PARALLEL=""
USE_ALL=""

#
# catch signals
#
trap "rm -f \"${TMP}\"" 1 2 15

#
# Functions
#

# time displaying echo
_techo()
{
   echo "$(${DDATE}): $@"
}

# exit on error
_exit_err()
{
   _techo "$@"
   rm -f "${TMP}"
   exit 1
}

add_name()
{
   awk "{ print \"[${name}] \" \$0 }"
}

#
# Execute on remote host, if backing up to a remote host
#
pcmd()
{
   if [ "${remote_host}" ]; then
      ssh "${remote_host}" "$@"
   else
      "$@"
   fi
}

delete_from_file()
{
   #
   # ssh-"feature": we cannot do '... read ...; ssh  ...; < file',
   # because ssh reads stdin! -n does not work -> does not ask for password
   #
   file="$1"; shift
   while read to_remove; do set -- "$@" "${ddir}/${to_remove}"; done < "${file}"
   _techo "Removing $@ ..."
   pcmd rm ${VVERBOSE} -rf "$@" || _exit_err "Removing $@ failed."
}

display_version()
{
   echo "${FULL_VERSION}"
   exit 0
}

usage()
{
   cat << eof
${__myname}: [args] <interval name> <sources to backup>

   ccollect creates (pseudo) incremental backups

   -h, --help:          Show this help screen
   -p, --parallel:      Parallelise backup processes
   -a, --all:           Backup all sources specified in ${CSOURCES}
   -v, --verbose:       Be very verbose (uses set -x)
   -V, --version:       Print version information

   This is version ${VERSION}, released on ${RELEASE}
   (the first version was written on 2005-12-05 by Nico Schottelius).

   Retrieve latest ccollect at http://www.nico.schottelius.org/software/ccollect/
eof
   exit 0
}

#
# Parse options
#
while [ "$#" -ge 1 ]; do
   case "$1" in
      -a|--all)
         USE_ALL=1
         ;;
      -v|--verbose)
         set -x
         ;;
      -p|--parallel)
         PARALLEL=1
         ;;
      -h|--help)
         usage
         ;;
      -V|--version)
         display_version
         ;;
      -h|--help|-*)
         usage
         ;;
      --)
         # ignore the -- itself
         shift
         break
         ;;
      *)
         break
         ;;
   esac
   shift
done

#
# Setup interval
#
if [ $# -ge 1 ]; then
   export INTERVAL="$1"
   shift
else
   usage
fi

#
# Check for configuraton directory
#
[ -d "${CCOLLECT_CONF}" ] || _exit_err "No configuration found in " \
   "\"${CCOLLECT_CONF}\" (is \$CCOLLECT_CONF properly set?)"

#
# Create (portable!) source "array"
#
export no_sources=0

if [ "${USE_ALL}" = 1 ]; then
   #
   # Get sources from source configuration
   #
   ( cd "${CSOURCES}" && ls -1 > "${TMP}" ); ret=$?

   [ "${ret}" -eq 0 ] || _exit_err "Listing of sources failed. Aborting."

   while read tmp; do
      eval export source_${no_sources}=\"${tmp}\"
      no_sources=$((${no_sources}+1))
   done < "${TMP}"
else
   #
   # Get sources from command line
   #
   while [ "$#" -ge 1 ]; do
      eval arg=\"\$1\"; shift

      eval export source_${no_sources}=\"${arg}\"
      no_sources="$((${no_sources}+1))"
   done
fi

#
# Need at least ONE source to backup
#
if [ "${no_sources}" -lt 1 ]; then
   usage
else
   _techo "${HALF_VERSION}: Beginning backup using interval ${INTERVAL}"
fi

#
# Look for pre-exec command (general)
#
if [ -x "${CPREEXEC}" ]; then
   _techo "Executing ${CPREEXEC} ..."
   "${CPREEXEC}"; ret=$?
   _techo "Finished ${CPREEXEC} (return code: ${ret})."

   [ "${ret}" -eq 0 ] || _exit_err "${CPREEXEC} failed. Aborting"
fi

#
# Let's do the backup
#
i=0
while [ "${i}" -lt "${no_sources}" ]; do
   #
   # Get current source
   #
   eval name=\"\$source_${i}\"
   i=$((${i}+1))

   export name

   #
   # start ourself, if we want parallel execution
   #
   if [ "${PARALLEL}" ]; then
      "$0" "${INTERVAL}" "${name}" &
      continue
   fi

#
# Start subshell for easy log editing
#
(
   backup="${CSOURCES}/${name}"
   #
   # Stderr to stdout, so we can produce nice logs
   #
   exec 2>&1

   #
   # Record start of backup: internal and for the user
   #
   begin_s="$(${SDATE})"
   _techo "Beginning to backup"

   #
   # Standard configuration checks
   #
   if [ ! -e "${backup}" ]; then
      _exit_err "Source does not exist."
   fi

   #
   # Configuration _must_ be a directory (cconfig style)
   #
   if [ ! -d "${backup}" ]; then
      _exit_err "\"${name}\" is not a cconfig-directory. Skipping."
   fi

   #
   # Read / create configuration
   #
   c_source="${backup}/source"
   c_dest="${backup}/destination"
   c_pre_exec="${backup}/pre_exec"
   c_post_exec="${backup}/post_exec"
   c_marker="ccollect-marker"
   for opt in verbose very_verbose summary exclude rsync_options \
              delete_incomplete remote_host rsync_failure_codes  \
              mtime quiet_if_down ; do
      if [ -f "${backup}/${opt}" -o -f "${backup}/no_${opt}"  ]; then
         eval c_$opt=\"${backup}/$opt\"
      else
         eval c_$opt=\"${CDEFAULTS}/$opt\"
      fi
   done

   #
   # Sort by ctime (default) or mtime (configuration option)
   #
   if [ -f "$c_mtime" ] ; then
      TSORT="t"
   else
      TSORT="tc"
   fi

   #
   # First execute pre_exec, which may generate destination or other parameters
   #
   if [ -x "${c_pre_exec}" ]; then
      _techo "Executing ${c_pre_exec} ..."
      "${c_pre_exec}"; ret="$?"
      _techo "Finished ${c_pre_exec} (return code ${ret})."

      if [ "${ret}" -ne 0 ]; then
         _exit_err "${c_pre_exec} failed. Skipping."
      fi
   fi

   #
   # Source configuration checks
   #
   if [ ! -f "${c_source}" ]; then
      _exit_err "Source description \"${c_source}\" is not a file. Skipping."
   else
      source=$(cat "${c_source}"); ret="$?"
      if [ "${ret}" -ne 0 ]; then
         _exit_err "Source ${c_source} is not readable. Skipping."
      fi
   fi

   #
   # Destination is a path
   #
   if [ ! -f "${c_dest}" ]; then
      _exit_err "Destination ${c_dest} is not a file. Skipping."
   else
      ddir="$(cat "${c_dest}")"; ret="$?"
      if [ "${ret}" -ne 0 ]; then
         _exit_err "Destination ${c_dest} is not readable. Skipping."
      fi
   fi

   #
   # Set pre-cmd, if we backup to a remote host.
   #
   if [ -f "${c_remote_host}" ]; then
      remote_host="$(cat "${c_remote_host}")"; ret="$?"
      if [ "${ret}" -ne 0 ]; then
         _exit_err "Remote host file ${c_remote_host} exists, but is not readable. Skipping."
      fi
      destination="${remote_host}:${ddir}"
   else
      remote_host=""
      destination="${ddir}"
   fi
   export remote_host

   #
   # Parameters: ccollect defaults, configuration options, user options
   #

   #
   # Rsync standard options
   #
   set -- "$@" "--archive" "--delete" "--numeric-ids" "--relative"   \
               "--delete-excluded" "--sparse"

   #
   # Exclude list
   #
   if [ -f "${c_exclude}" ]; then
      set -- "$@" "--exclude-from=${c_exclude}"
   fi

   #
   # Output a summary
   #
   if [ -f "${c_summary}" ]; then
      set -- "$@" "--stats"
   fi

   #
   # Verbosity for rsync, rm, and mkdir
   #
   VVERBOSE=""
   if [ -f "${c_very_verbose}" ]; then
      set -- "$@" "-vv"
      VVERBOSE="-v"
   elif [ -f "${c_verbose}" ]; then
      set -- "$@" "-v"
   fi

   #
   # Extra options for rsync provided by the user
   #
   if [ -f "${c_rsync_options}" ]; then
      while read line; do
         set -- "$@" "$line"
      done < "${c_rsync_options}"
   fi

   #
   # Check: source is up and accepting connections (before deleting old backups!)
   #
   if ! rsync "${source}" >/dev/null 2>"${TMP}" ; then
      if [ ! -f "${c_quiet_if_down}" ]; then
         cat "${TMP}"
      fi
      _exit_err "Source ${source} is not readable. Skipping."
   fi

   #
   # Check: destination exists?
   #
   ( pcmd cd "${ddir}" ) || _exit_err "Cannot change to ${ddir}. Skipping."

   #
   # Check: incomplete backups? (needs echo to remove newlines)
   #
   incomplete="$(echo \
      $(pcmd ls -1 "${ddir}/" | \
      awk "/\.${c_marker}\$/ { print \$0; gsub(\"\.${c_marker}\$\",\"\",\$0); print \$0 }" | \
      tee "${TMP}"))"

   if [ "${incomplete}" ]; then
      _techo "Incomplete backups: ${incomplete}"
      if [ -f "${c_delete_incomplete}" ]; then
         delete_from_file "${TMP}"
      fi
   fi

   #
   # Interval definition: First try source specific, fallback to default
   #
   c_interval="$(cat "${backup}/intervals/${INTERVAL}" 2>/dev/null)"

   if [ -z "${c_interval}" ]; then
      c_interval="$(cat "${CDEFAULTS}/intervals/${INTERVAL}" 2>/dev/null)"

      if [ -z "${c_interval}" ]; then
         _exit_err "No definition for interval \"${INTERVAL}\" found. Skipping."
      fi
   fi

   #
   # Check: maximum number of backups is reached?
   # If so remove. Use grep and ls -p so we only look at directories
   #
   count="$(pcmd ls -p1 "${ddir}" | grep "^${INTERVAL}\..*/\$" | wc -l \
      | sed 's/^ *//g')"  || _exit_err "Counting backups failed"

   _techo "Existing backups: ${count} Total keeping backups: ${c_interval}"

   if [ "${count}" -ge "${c_interval}" ]; then
      substract="$((${c_interval} - 1))"
      remove="$((${count} - ${substract}))"
      _techo "Removing ${remove} backup(s)..."

      pcmd ls -${TSORT}p1r "${ddir}" | grep "^${INTERVAL}\..*/\$" | \
        head -n "${remove}" > "${TMP}"      || \
        _exit_err "Listing old backups failed"

      delete_from_file "${TMP}"
   fi

   #
   # Check for backup directory to clone from: Always clone from the latest one!
   #
   last_dir="$(pcmd ls -${TSORT}p1 "${ddir}" | grep '/$' | head -n 1)" || \
      _exit_err "Failed to list contents of ${ddir}."

   #
   # clone from old backup, if existing
   #
   if [ "${last_dir}" ]; then
      set -- "$@" "--link-dest=${ddir}/${last_dir}"
      _techo "Hard linking from ${last_dir}"
   fi

   # set time when we really begin to backup, not when we began to remove above
   destination_date="$(${CDATE})"
   destination_dir="${ddir}/${INTERVAL}.${destination_date}.$$"
   destination_full="${destination}/${INTERVAL}.${destination_date}.$$"

   # give some info
   _techo "Beginning to backup, this may take some time..."

   _techo "Creating ${destination_dir} ..."
   pcmd mkdir ${VVERBOSE} "${destination_dir}" || \
      _exit_err "Creating ${destination_dir} failed. Skipping."

   #
   # added marking in 0.6 (and remove it, if successful later)
   #
   pcmd touch "${destination_dir}.${c_marker}"

   #
   # the rsync part
   #
   _techo "Transferring files..."
   rsync "$@" "${source}" "${destination_full}"; ret=$?
   _techo "Finished backup (rsync return code: $ret)."

   #
   # Set modification time (mtime) to current time, if sorting by mtime is enabled
   #
   [ -f "$c_mtime" ] && pcmd touch "${destination_dir}"

   #
   # Check if rsync exit code indicates failure.
   #
   fail=""
   if [ -f "$c_rsync_failure_codes" ]; then
      while read code ; do
         if [ "$ret" = "$code" ]; then
            fail=1
         fi
      done <"$c_rsync_failure_codes"
   fi

   #
   # Remove marking here unless rsync failed.
   #
   if [ -z "$fail" ]; then
      pcmd rm "${destination_dir}.${c_marker}" || \
         _exit_err "Removing ${destination_dir}.${c_marker} failed."
      if [ "${ret}" -ne 0 ]; then
         _techo "Warning: rsync exited non-zero, the backup may be broken (see rsync errors)."
      fi
   else
      _techo "Warning: rsync failed with return code $ret."
   fi

   #
   # post_exec
   #
   if [ -x "${c_post_exec}" ]; then
      _techo "Executing ${c_post_exec} ..."
      "${c_post_exec}"; ret=$?
      _techo "Finished ${c_post_exec}."

      if [ "${ret}" -ne 0 ]; then
         _exit_err "${c_post_exec} failed."
      fi
   fi

   # Calculation
   end_s="$(${SDATE})"

   full_seconds="$((${end_s} - ${begin_s}))"
   hours="$((${full_seconds} / 3600))"
   seconds="$((${full_seconds} - (${hours} * 3600)))"
   minutes="$((${seconds} / 60))"
   seconds="$((${seconds} - (${minutes} * 60)))"

   _techo "Backup lasted: ${hours}:${minutes}:${seconds} (h:m:s)"

) | add_name
done

#
# Be a good parent and wait for our children, if they are running wild parallel
#
if [ "${PARALLEL}" ]; then
   _techo "Waiting for children to complete..."
   wait
fi

#
# Look for post-exec command (general)
#
if [ -x "${CPOSTEXEC}" ]; then
   _techo "Executing ${CPOSTEXEC} ..."
   "${CPOSTEXEC}"; ret=$?
   _techo "Finished ${CPOSTEXEC} (return code: ${ret})."

   if [ "${ret}" -ne 0 ]; then
      _techo "${CPOSTEXEC} failed."
   fi
fi

rm -f "${TMP}"
_techo "Finished"

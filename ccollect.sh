#!/bin/sh
# Nico Schottelius
# Initially written for SyGroup (www.sygroup.ch)
# Date: Mon Nov 14 11:45:11 CET 2005
# Last Modified: (See ls -l or git)

#
# where to find our configuration and temporary file
#
CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
CSOURCES=${CCOLLECT_CONF}/sources
CDEFAULTS=${CCOLLECT_CONF}/defaults
CPREEXEC="${CDEFAULTS}/pre_exec"
CPOSTEXEC="${CDEFAULTS}/post_exec"

TMP=$(mktemp "/tmp/$(basename $0).XXXXXX")
VERSION=0.6.2
RELEASE="2007-08-27"
HALF_VERSION="ccollect ${VERSION}"
FULL_VERSION="ccollect ${VERSION} (${RELEASE})"

#
# CDATE: how we use it for naming of the archives
# DDATE: how the user should see it in our output (DISPLAY)
#
CDATE="date +%Y%m%d-%H%M"
DDATE="date +%Y-%m-%d-%H:%M:%S"

#
# unset parallel execution
#
PARALLEL=""

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
   sed "s:^:\[${name}\] :"
}

#
# Version
#
display_version()
{
   echo "${FULL_VERSION}"
   exit 0
}

#
# Tell how to use us
#
usage()
{
   echo "$(basename $0): <interval name> [args] <sources to backup>"
   echo ""
   echo "   ccollect creates (pseudo) incremental backups"
   echo ""
   echo "   -h, --help:          Show this help screen"
   echo "   -p, --parallel:      Parallelise backup processes"
   echo "   -a, --all:           Backup all sources specified in ${CSOURCES}"
   echo "   -v, --verbose:       Be very verbose (uses set -x)"
   echo "   -V, --version:       Print version information"
   echo ""
   echo "   This is version ${VERSION}, released on ${RELEASE}"
   echo "   (the first version was written on 2005-12-05 by Nico Schottelius)."
   echo ""
   echo "   Retrieve latest ccollect at http://unix.schottelius.org/ccollect/"
   exit 0
}

#
# need at least interval and one source or --all
#
if [ $# -lt 2 ]; then
   if [ "$1" = "-V" -o "$1" = "--version" ]; then
      display_version
   else
      usage
   fi
fi

#
# check for configuraton directory
#
[ -d "${CCOLLECT_CONF}" ] || _exit_err "No configuration found in " \
   "\"${CCOLLECT_CONF}\" (is \$CCOLLECT_CONF properly set?)"

#
# Filter arguments
#
export INTERVAL="$1"; shift
i=1
no_sources=0

#
# Create source "array"
#
while [ "$#" -ge 1 ]; do
   eval arg=\"\$1\"; shift

   if [ "${NO_MORE_ARGS}" = 1 ]; then
        eval source_${no_sources}=\"${arg}\"
        no_sources=$((${no_sources}+1))
        
        # make variable available for subscripts
        eval export source_${no_sources}
   else
      case "${arg}" in
         -a|--all)
            ALL=1
            ;;
         -v|--verbose)
            VERBOSE=1
            ;;
         -p|--parallel)
            PARALLEL=1
            ;;
         -h|--help)
            usage
            ;;
         --)
            NO_MORE_ARGS=1
            ;;
         *)
            eval source_${no_sources}=\"$arg\"
            no_sources=$(($no_sources+1))
            ;;
      esac
   fi

   i=$(($i+1))
done

# also export number of sources
export no_sources

#
# be really, really, really verbose
#
if [ "${VERBOSE}" = 1 ]; then
   set -x
fi

#
# Look, if we should take ALL sources
#
if [ "${ALL}" = 1 ]; then
   # reset everything specified before
   no_sources=0

   #
   # get entries from sources
   #
   cwd=$(pwd -P)
   ( cd "${CSOURCES}" && ls > "${TMP}" ); ret=$?

   [ "${ret}" -eq 0 ] || _exit_err "Listing of sources failed. Aborting."

   while read tmp; do
      eval source_${no_sources}=\"${tmp}\"
      no_sources=$((${no_sources}+1))
   done < "${TMP}"
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
# check default configuration
#

D_FILE_INTERVAL="${CDEFAULTS}/intervals/${INTERVAL}"
D_INTERVAL=$(cat "${D_FILE_INTERVAL}" 2>/dev/null)


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
   #
   # Stderr to stdout, so we can produce nice logs
   #
   exec 2>&1

   #
   # Configuration
   #
   backup="${CSOURCES}/${name}"
   c_source="${backup}/source"
   c_dest="${backup}/destination"
   c_exclude="${backup}/exclude"
   c_verbose="${backup}/verbose"
   c_vverbose="${backup}/very_verbose"
   c_rsync_extra="${backup}/rsync_options"
   c_summary="${backup}/summary"
   c_pre_exec="${backup}/pre_exec"
   c_post_exec="${backup}/post_exec"
   c_incomplete="${backup}/delete_incomplete"

   #
   # Marking backups: If we abort it's not removed => Backup is broken
   #
   c_marker=".ccollect-marker"

   #
   # Times
   #
   begin_s=$(date +%s)

   #
   # unset possible options
   #
   EXCLUDE=""
   RSYNC_EXTRA=""
   SUMMARY=""
   VERBOSE=""
   VVERBOSE=""
   DELETE_INCOMPLETE=""

   _techo "Beginning to backup"

   #
   # Standard configuration checks
   #
   if [ ! -e "${backup}" ]; then
      _exit_err "Source does not exist."
   fi

   #
   # configuration _must_ be a directory
   #
   if [ ! -d "${backup}" ]; then
      _exit_err "\"${name}\" is not a cconfig-directory. Skipping."
   fi

   #
   # first execute pre_exec, which may generate destination or other
   # parameters
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
   # interval definition: First try source specific, fallback to default
   #
   c_interval="$(cat "${backup}/intervals/${INTERVAL}" 2>/dev/null)"

   if [ -z "${c_interval}" ]; then
      c_interval="${D_INTERVAL}"

      if [ -z "${c_interval}" ]; then
         _exit_err "No definition for interval \"${INTERVAL}\" found. Skipping."
      fi
   fi

   #
   # Source checks
   #
   if [ ! -f "${c_source}" ]; then
      _exit_err "Source description \"${c_source}\" is not a file. Skipping."
   else
      source=$(cat "${c_source}"); ret=$?
      if [ ${ret} -ne 0 ]; then
         _exit_err "Source ${c_source} is not readable. Skipping."
      fi
   fi

   #
   # destination _must_ be a directory
   #
   if [ ! -d "${c_dest}" ]; then
      _exit_err "Destination ${c_dest} is not a directory. Skipping."
   fi

   #
   # Check whether to delete incomplete backups
   #
   if [ -f "${c_incomplete}" ]; then
      DELETE_INCOMPLETE="yes"
   fi

   # NEW method as of 0.6:
   # - insert ccollect default parameters
   # - insert options
   # - insert user options
   
   #
   # rsync standard options
   #

   set -- "$@" "--archive" "--delete" "--numeric-ids" "--relative"   \
                "--delete-excluded" "--sparse" 

   #
   # exclude list
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
   # Verbosity for rsync
   #
   if [ -f "${c_vverbose}" ]; then
      set -- "$@" "-vv"
   elif [ -f "${c_verbose}" ]; then
      set -- "$@" "-v"
   fi

   #
   # extra options for rsync provided by the user
   #
   if [ -f "${c_rsync_extra}" ]; then
      while read line; do
         set -- "$@" "$line"
      done < "${c_rsync_extra}"
   fi

   #
   # Check for incomplete backups
   #
   ( cd "${c_dest}" 2>/dev/null && ls -1 "${INTERVAL}"*".${c_marker}" > "${TMP}" 2>/dev/null)

   while read incomplete; do
      realincomplete=$(echo ${incomplete} | sed "s/\\.${c_marker}\$//")
      _techo "Incomplete backup: ${realincomplete}"
      if [ "${DELETE_INCOMPLETE}" = "yes" ]; then
         _techo "Deleting ${realincomplete} ..."
         rm $VVERBOSE -rf "${c_dest}/${realincomplete}" || \
            _exit_err "Removing ${realincomplete} failed."
      fi
   done < "${TMP}"


   #
   # check if maximum number of backups is reached, if so remove
   # use grep and ls -p so we only look at directories
   #
   count=$(cd "${c_dest}" && ls -p1 | grep "^${INTERVAL}\..*/\$" | wc -l \
      | sed 's/^ *//g')  || _exit_err "Counting backups failed"

   _techo "Existing backups: ${count} Total keeping backups: ${c_interval}"
   
   if [ "${count}" -ge "${c_interval}" ]; then
      substract=$((${c_interval} - 1))
      remove=$((${count} - ${substract}))
      _techo "Removing ${remove} backup(s)..."

      ( cd "${c_dest}" 2>/dev/null && ls -p1 | grep "^${INTERVAL}\..*/\$" | \
        sort -n | head -n "${remove}" ) > "${TMP}"

      while read to_remove; do
         _techo "Removing ${to_remove} ..."
         rm ${VVERBOSE} -rf "${c_dest}/${to_remove}" || \
            _exit_err "Removing ${to_remove} failed."
      done < "${TMP}"
   fi


   #
   # Check for backup directory to clone from: Always clone from the latest one!
   #
   # Use ls -1c instead of -1t, because last modification maybe the same on all
   # and metadate update (-c) is updated by rsync locally.
   #
   rel_last_dir="$(cd "${c_dest}" && ls -tcp1 | grep '/$' | head -n 1)" || \
      _exit_err "Failed to list contents of ${c_dest}."
   last_dir="${c_dest}/${rel_last_dir}"
   
   #
   # clone from old backup, if existing
   #
   if [ "${last_dir}" ]; then
      # must be absolute, otherwise rsync uses it relative to
      # the destination directory. See rsync(1).
      abs_last_dir="$(cd "${last_dir}" && pwd -P)" || \
         _exit_err "Could not change to last dir ${last_dir}."
      set -- "$@" "--link-dest=${abs_last_dir}"
      _techo "Hard linking from ${rel_last_dir}"
   fi
      

   # set time when we really begin to backup, not when we began to remove above
   destination_date=$(${CDATE})
   destination_dir="${c_dest}/${INTERVAL}.${destination_date}.$$"

   # give some info
   _techo "Beginning to backup, this may take some time..."

   _techo "Creating ${destination_dir} ..."
   mkdir ${VVERBOSE} "${destination_dir}" || \
      _exit_err "Creating ${destination_dir} failed. Skipping."

   # absulte now, it's existing
   abs_destination_dir="$(cd "${destination_dir}" && pwd -P)" || \
      _exit_err "Changing to newly created ${destination_dir} failed. Skipping."

   #
   # added marking in 0.6 (and remove it, if successful later)
   #
   touch "${abs_destination_dir}.${c_marker}"

   #
   # the rsync part
   #

   _techo "Transferring files..."
   rsync "$@" "${source}" "${abs_destination_dir}"; ret=$?

   #
   # remove marking here
   #
   rm "${abs_destination_dir}.${c_marker}" || \
      _exit_err "Removing ${abs_destination_dir}/${c_marker} failed."

   _techo "Finished backup (rsync return code: $ret)."
   if [ "${ret}" -ne 0 ]; then
      _techo "Warning: rsync exited non-zero, the backup may be broken (see rsync errors)."
   fi

   #
   # post_exec
   #
   if [ -x "${c_post_exec}" ]; then
      _techo "Executing ${c_post_exec} ..."
      "${c_post_exec}"; ret=$?
      _techo "Finished ${c_post_exec}."

      if [ ${ret} -ne 0 ]; then
         _exit_err "${c_post_exec} failed."
      fi
   fi

   # Calculation
   end_s=$(date +%s)

   full_seconds=$((${end_s} - ${begin_s}))
   hours=$((${full_seconds} / 3600))
   seconds=$((${full_seconds} - (${hours} * 3600)))
   minutes=$((${seconds} / 60))
   seconds=$((${seconds} - (${minutes} * 60)))

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

   if [ ${ret} -ne 0 ]; then
      _techo "${CPOSTEXEC} failed."
   fi
fi

rm -f "${TMP}"
_techo "Finished ${WE}"

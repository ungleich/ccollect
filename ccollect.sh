#!/bin/sh
# Nico Schottelius
# written for SyGroup (www.sygroup.ch)
# Date: Mon Nov 14 11:45:11 CET 2005
# Last Modified: (See ls -l or git)

#
# where to find our configuration and temporary file
#
CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
CSOURCES=$CCOLLECT_CONF/sources
CDEFAULTS=$CCOLLECT_CONF/defaults
CPREEXEC="$CDEFAULTS/pre_exec"
CPOSTEXEC="$CDEFAULTS/post_exec"

TMP=$(mktemp /tmp/$(basename $0).XXXXXX)
VERSION=0.5.2
RELEASE="2007-01-27"
HALF_VERSION="ccollect $VERSION"
FULL_VERSION="ccollect $VERSION ($RELEASE)"

#
# CDATE: how we use it for naming of the archives
# DDATE: how the user should see it in our output
#
CDATE="date +%Y-%m-%d-%H%M"
DDATE="date"

#
# unset parallel execution
#
PARALLEL=""

#
# catch signals
#
trap "rm -f \"$TMP\"" 1 2 15

#
# Functions
#

_exit_err()
{
   echo "$@"
   rm -f "$TMP"
   exit 1
}

add_name()
{
   sed "s:^:\[$name\] :"
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
   echo "   -a, --all:           Backup all sources specified in $CSOURCES"
   echo "   -v, --verbose:       Be very verbose (uses set -x)."
   echo ""
   echo "   This is version $VERSION, released on ${RELEASE}"
   echo "   (the first version was written on 2005-12-05 by Nico Schottelius)."
   echo ""
   echo "   Retrieve latest ccollect at http://unix.schottelius.org/ccollect/"
   exit 0
}

#
# need at least interval and one source or --all
#
if [ $# -lt 2 ]; then
   usage
fi

#
# check for configuraton directory, FIXME: _exit_err
#
[ -d "$CCOLLECT_CONF" ] || _exit_err "No configuration found in " \
                        "\"$CCOLLECT_CONF\" (is \$CCOLLECT_CONF properly set?)"

#
# Filter arguments
#
INTERVAL=$1; shift
i=1
no_sources=0

while [ $i -le $# ]; do
   eval arg=\$$i

   if [ "$NO_MORE_ARGS" = 1 ]; then
        eval source_${no_sources}=\"$arg\"
        no_sources=$(($no_sources+1))
   else
      case $arg in
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

#
# be really, really, really verbose
#
if [ "$VERBOSE" = 1 ]; then
   set -x
fi

#
# Look for pre-exec command (general)
#
if [ -x "$CPREEXEC" ]; then
   echo "Executing $CPREEXEC ..."
   "$CPREEXEC"
   ret=$?
   echo "Finished ${CPREEXEC}."

   # FIXME: _exit_err
   if [ $ret -ne 0 ]; then
      echo "$CPREEXEC failed, not starting backup."
      exit 1
   fi
fi

#
# Look, if we should take ALL sources
#
if [ "$ALL" = 1 ]; then
   # reset everything specified before
   no_sources=0

   #
   # get entries from sources
   #
   cwd=$(pwd -P)
   ( cd "$CSOURCES" && ls > "$TMP" )

   # FIXME: _exit_err
   if [ "$?" -ne 0 ]; then
      echo "Listing of sources failed. Aborting."
      exit 1
   fi

   while read tmp; do
      eval source_${no_sources}=\"$tmp\"
      no_sources=$(($no_sources+1))
   done < "$TMP"
fi

#
# Need at least ONE source to backup
#
if [ "$no_sources" -lt 1 ]; then
   usage
else
   echo "==> $HALF_VERSION: Beginning backup using interval $INTERVAL <=="
fi

#
# check default configuration
#

D_FILE_INTERVAL="$CDEFAULTS/intervals/$INTERVAL"
D_INTERVAL=$(cat "$D_FILE_INTERVAL" 2>/dev/null)

#
# Let's do the backup
#
i=0
while [ "$i" -lt "$no_sources" ]; do

   #
   # Get current source
   #
   eval name=\"\$source_${i}\"
   i=$(($i+1))

   export name

   #
   # start ourself, if we want parallel execution
   #
   if [ "$PARALLEL" ]; then
      "$0" "$INTERVAL" "$name" &
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
   # Standard locations
   #
   backup="$CSOURCES/$name"
   c_source="$backup/source"
   c_dest="$backup/destination"
   c_exclude="$backup/exclude"
   c_verbose="$backup/verbose"
   c_vverbose="$backup/very_verbose"
   c_rsync_extra="$backup/rsync_options"
   c_summary="$backup/summary"

   #
   # FIXME: enable in 0.6
   #
   #c_incomplete="$backup/incomplete_remove"
   #c_marker=".ccollect-${CDATE}.$$"

   c_pre_exec="$backup/pre_exec"
   c_post_exec="$backup/post_exec"

   begin=$($DDATE)
   begin_s=$(date +%s)

   #
   # unset possible options
   #
   EXCLUDE=""
   RSYNC_EXTRA=""
   SUMMARY=""
   VERBOSE=""
   VVERBOSE=""

   echo "$begin Beginning to backup"

   #
   # Standard configuration checks
   #
   if [ ! -e "$backup" ]; then
      echo "Source does not exist."
      exit 1
   fi

   #
   # configuration _must_ be a directory
   #
   if [ ! -d "$backup" ]; then
      echo "\"$name\" is not a cconfig-directory. Skipping."
      exit 1
   fi

   #
   # first execute pre_exec, which may generate destination or other
   # parameters
   #
   if [ -x "$c_pre_exec" ]; then
      echo "Executing ${c_pre_exec} ..."
      "$c_pre_exec"
      ret="$?"
      echo "Finished ${c_pre_exec}."

      if [ "$ret" -ne 0 ]; then
         echo "$c_pre_exec failed. Skipping."
         exit 1
      fi
   fi

   #
   # interval definition: First try source specific, fallback to default
   #
   c_interval="$(cat "$backup/intervals/$INTERVAL" 2>/dev/null)"

   if [ -z "$c_interval" ]; then
      c_interval="$D_INTERVAL"

      if [ -z "$c_interval" ]; then
         echo "No definition for interval \"$INTERVAL\" found. Skipping."
         exit 1
      fi
   fi

   #
   # Source checks
   #
   if [ ! -f "$c_source" ]; then
      echo "Source description $c_source is not a file. Skipping."
      exit 1
   else
      source=$(cat "$c_source")
      if [ $? -ne 0 ]; then
         echo "Source $c_source is not readable. Skipping."
         exit 1
      fi
   fi

   #
   # destination _must_ be a directory
   #
   if [ ! -d "$c_dest" ]; then
      echo "Destination $c_dest neither links to nor is a directory. Skipping."
      exit 1
   fi

   #
   # exclude list
   #
   if [ -f "$c_exclude" ]; then
      # FIXME: check how quoting at the end looks like
      # perhaps our source contains spaces!
      EXCLUDE="--exclude-from=$c_exclude"
   fi

   #
   # extra options for rsync
   #
   if [ -f "$c_rsync_extra" ]; then
      RSYNC_EXTRA="$(cat "$c_rsync_extra")"
   fi

   #
   # Output a summary
   #
   if [ -f "$c_summary" ]; then
      SUMMARY="--stats"
   fi

   #
   # Verbosity for rsync
   #
   if [ -f "$c_verbose" ]; then
      VERBOSE="-v"
   fi

   #
   # MORE verbosity, includes standard verbosity
   #
   if [ -f "$c_vverbose" ]; then
      VERBOSE="-v"
      VVERBOSE="-v"
   fi

#   #
#   # show if we shall remove partial backup, and whether the last one
#   # is incomplete or not
#   #
#   # FIXME: test general for incomplete and decide only for warn|delete based on option?
#   # FIXME: Define which is the last dir before? Or put this thing into
#   # a while loop? Is it senseful to remove _ALL_ backups if non is complete?
#   if [ -f "$c_incomplete" ]; then
#      last_dir=$(ls -d "$c_dest/${INTERVAL}."?* 2>/dev/null | sort -n | tail -n 1)
#
#      # check whether the last backup was incomplete
#      # STOPPED HERE
#      # todo: implement rm -rf, implement warning on non-cleaning
#      # implement the marknig and normal removing
#      if [ "$last_dir" ]; then
#         incomplete=$(cd "$last_dir" && ls .ccollect-????-??-)
#         if [ "$incomplete" ]; then
#            "Removing incomplete backup $last_dir ..."
#            echo rm -rf $VVERBOSE "$last_dir"
#         fi
#      fi
#   fi
#
   #
   # check if maximum number of backups is reached, if so remove
   #

   # the created directories are named $INTERVAL-$DATE-$TIME.$PID
   count=$(cd "$c_dest" && ls -p1 | grep "^${INTERVAL}\..*/\$" | wc -l | sed 's/^ *//g')
   echo -n "Currently $count backup(s) exist(s),"
   echo " total keeping $c_interval backup(s)."

   if [ "$count" -ge "$c_interval" ]; then
      substract=$((${c_interval} - 1))
      remove=$(($count - $substract))
      echo "Removing $remove backup(s)..."

      ls -d "$c_dest/${INTERVAL}."?* | sort -n | head -n "$remove" > "$TMP"
      #( cd "$c_dest" && ls -p1 | grep "^${INTERVAL}\..*/\$" | sort -n | head -n $remove > "$TMP"
      while read to_remove; do
         dir="$to_remove"
         echo "Removing $dir ..."
         rm $VVERBOSE -rf "$dir"
      done < "$TMP"
   fi

   #
   # clone the old directory with hardlinks
   #

   # FIXME: STOPPED

   destination_date=$($CDATE)
   destination_dir="$c_dest/${INTERVAL}.${destination_date}.$$"

   #
   # FIXME: In 0.6 add search for the latest available backup!
   #
   last_dir=$(ls -d "$c_dest/${INTERVAL}."?* 2>/dev/null | sort -n | tail -n 1)

   # give some info
   echo "Beginning to backup, this may take some time..."

   echo "Creating $destination_dir ..."
   mkdir $VVERBOSE "$destination_dir" || \
      _exit_err "Creating $destination_dir failed. Skipping."

   #
   # make an absolute path, perhaps $CCOLLECT_CONF is relative!
   #
   abs_destination_dir="$(cd "$destination_dir" && pwd -P)"

   #
   # FIXME: add mark in 0.6 (and remove if successful later!
   #
   #touch "${abs_destination_dir}/${c_marker}"

   #
   # the rsync part
   # options partly stolen from rsnapshot
   #

   echo "$($DDATE) Transferring files..."

   ouropts="-a --delete --numeric-ids --relative --delete-excluded"

   #
   # FIXME: check, whether this is broken with spaces...
   # most likely it should be broken...MUST be...
   # expanding depens on shell (zsh = 1, dash = 3 arguments in test case)
   #
   useropts="$VERBOSE $EXCLUDE $SUMMARY $RSYNC_EXTRA"

   #
   # FIXME:useropts / rsync extra: one parameter per line!
   # 0.5.3!
   #

   # Clone from previous backup, if existing
   if [ "$last_dir" ]; then

      #
      # This directory MUST be absolute, because rsync does chdir()
      # before beginning backup!
      #

      abs_last_dir="$(cd "$last_dir" && pwd -P)"
      if [ -z "$abs_last_dir" ]; then
         echo "Changing to the last backup directory failed. Skipping."
         exit 1
      fi

      rsync_hardlink="--link-dest=$abs_last_dir"
      rsync $ouropts "$rsync_hardlink" $useropts "$source" "$abs_destination_dir"
   else
      rsync $ouropts $useropts "$source" "$abs_destination_dir"
   fi

   ret=$?

   if [ "$ret" -ne 0 ]; then
      echo "rsync reported error $ret. The backup may be broken (see rsync errors)."
   fi

   #
   # FIXME: remove marking here
   # rm -f $c_marker
   #

   echo "$($DDATE) Finished backup"

   #
   # post_exec
   #
   if [ -x "$c_post_exec" ]; then
      echo "$($DDATE) Executing $c_post_exec ..."
      "$c_post_exec"
      ret=$?
      echo "$($DDATE) Finished ${c_post_exec}."

      if [ $ret -ne 0 ]; then
         echo "$c_post_exec failed."
      fi
   fi

   end_s=$(date +%s)

   full_seconds=$((${end_s} - ${begin_s}))
   hours=$(($full_seconds / 3600))
   seconds=$(($full_seconds - ($hours * 3600)))
   minutes=$(($seconds / 60))
   seconds=$((${seconds} - (${minutes} * 60)))

   echo "Backup lasted: ${hours}:${minutes}:${seconds} (h:m:s)"

) | add_name
done

#
# Be a good parent and wait for our children, if they are running wild parallel
#
if [ "$PARALLEL" ]; then
   echo "$($DDATE) Waiting for child jobs to complete..."
   wait
fi

#
# Look for post-exec command (general)
#
if [ -x "$CPOSTEXEC" ]; then
   echo "$($DDATE) Executing $CPOSTEXEC ..."
   "$CPOSTEXEC"
   ret=$?
   echo "$($DDATE) Finished ${CPOSTEXEC}."

   if [ $ret -ne 0 ]; then
      echo "$CPOSTEXEC failed."
   fi
fi

rm -f "$TMP"
echo "==> Finished $WE <=="

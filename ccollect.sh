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
VERSION=0.4.2
RELEASE="2006-06-17"
HALF_VERSION="ccollect $VERSION"
FULL_VERSION="ccollect $VERSION ($RELEASE)"

#
# Date
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
   echo "   Retrieve latest ccollect at http://linux.schottelius.org/ccollect/"
   exit 0
}

#
# need at least interval and one source or --all
#
if [ $# -lt 2 ]; then
   usage
fi

#
# check for configuraton directory
#
if [ ! -d "$CCOLLECT_CONF" ]; then
   echo "No configuration found in \"$CCOLLECT_CONF\"" \
        " (set \$CCOLLECT_CONF corectly?)"
   exit 1
fi

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
            PARALLEL="1"
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
# be really really really verbose
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
   echo "Finished ${CPREEXEC}."

   if [ $? -ne 0 ]; then
      echo "$CPREEXEC failed, aborting backup."
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
   cwd=$(pwd)
   cd "$CSOURCES";
   ls > "$TMP"
   
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
   eval name=\$source_${i}
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
      echo "Executing $c_pre_exec ..."
      "$c_pre_exec"
      echo "Finished ${c_pre_exec}."

      if [ $? -ne 0 ]; then
         echo "$c_pre_exec failed, aborting backup."
         exit 1
      fi
   fi

   #
   # interval definition: First try source specific, fallback to default
   #
   c_interval="$(cat "$backup/intervals/$INTERVAL" 2>/dev/null)"

   if [ -z "$c_interval" ]; then
      c_interval=$D_INTERVAL

      if [ -z "$c_interval" ]; then
         echo "Default and source specific interval missing. Skipping."
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
         echo "Skipping: Source $c_source is not readable"
         exit 1
      fi
   fi

   #
   # destination _must_ be a directory
   #
   if [ ! -d "$c_dest" ]; then
      echo "Destination $c_dest does not link to a directory. Skipping"
      exit 1
   fi

   #
   # exclude list
   #
   if [ -f "$c_exclude" ]; then
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
 
   #
   # check if maximum number of backups is reached, if so remove
   #
 
   # the created directories are named $INTERVAL-$DATE-$TIME.$PID
   count=$(ls -d "$c_dest/${INTERVAL}."?*  2>/dev/null | wc -l | sed 's/^ *//g')
   echo -n "Currently $count backup(s) exist(s),"
   echo " total keeping $c_interval backup(s)."
 
   if [ "$count" -ge "$c_interval" ]; then
      substract=$(echo $c_interval - 1 | bc)
      remove=$(echo $count - $substract | bc)
      echo "Removing $remove backup(s)..."

      ls -d "$c_dest/${INTERVAL}."?* | sort -n | head -n $remove > "$TMP"
      while read to_remove; do
         dir="$to_remove"
         echo "Removing $dir ..."
         rm $VVERBOSE -rf "$dir"
      done < "$TMP"
   fi
 
   #
   # clone the old directory with hardlinks
   #

   destination_date=$($CDATE)
   destination_dir="$c_dest/${INTERVAL}.${destination_date}.$$"
 
   last_dir=$(ls -d "$c_dest/${INTERVAL}."?* 2>/dev/null | sort -n | tail -n 1)
 
   # give some info
   echo "Beginning to backup, this may take some time..."

   echo "Creating $destination_dir ..."
   mkdir $VVERBOSE "$destination_dir"

   #
   # make an absolute path, perhaps $CCOLLECT_CONF is relative!
   #
   abs_destination_dir=$(cd $destination_dir; pwd)

   # only copy if a directory exists
   if [ "$last_dir" ]; then
      echo "$($DDATE) Hard linking..."
      cd "$last_dir"
      pax -rwl -p e $VVERBOSE .  "$abs_destination_dir"
   fi

   if [ $? -ne 0 ]; then
      echo -n "$($DDATE) Creating/cloning backup directory failed."
      echo " Skipping backup."
      exit 1
   fi

   #
   # the rsync part
   # options partly stolen from rsnapshot
   #
 
   echo "$($DDATE) Transferring files..."

   rsync -a $VERBOSE $RSYNC_EXTRA $EXCLUDE $SUMMARY \
      --delete --numeric-ids --relative --delete-excluded \
      "$source" "$abs_destination_dir"
   
   if [ "$?" -ne 0 ]; then
      echo "rsync reported an error. The backup may be broken (see rsync errors)"
   fi

   echo "$($DDATE) Finished backup"

   #
   # post_exec
   #
   if [ -x "$c_post_exec" ]; then
      echo "$($DDATE) Executing $c_post_exec ..."
      "$c_post_exec"
      echo "$($DDATE) Finished ${c_post_exec}."

      if [ $? -ne 0 ]; then
         echo "$c_post_exec failed."
      fi
   fi

   end_s=$(date +%s)

   full_seconds=$(echo "$end_s - $begin_s" | bc -l)
   hours=$(echo $full_seconds / 3600 | bc)
   seconds=$(echo "$full_seconds - ($hours * 3600)" | bc)
   minutes=$(echo $seconds / 60 | bc)
   seconds=$(echo "$seconds - ($minutes * 60)" | bc)

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
   echo "$($DDATE) Finished ${CPOSTEXEC}."
 
   if [ $? -ne 0 ]; then
      echo "$CPOSTEXEC failed."
   fi
fi

rm -f "$TMP"
echo "==> Finished $WE <=="

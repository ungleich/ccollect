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
WE=$(basename $0)
VERSION=0.3
RELEASE="2006-01-22"

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
   sed "s/^/\[$name\] /"
}

#
# Tell how to use us
#
usage()
{
   echo "$WE: <intervall name> [args] <sources to backup>"
   echo ""
   echo "   Nico Schottelius (nico-linux-ccollect schottelius.org) - 2005-12-06"
   echo ""
   echo "   Backup data pseudo incremental"
   echo ""
   echo "   -h, --help:          Show this help screen"
   echo "   -p, --parallel:      Parellize backup process"
   echo "   -a, --all:           Backup all sources specified in $CSOURCES"
   echo "   -v, --verbose:       Be very verbose."
   echo ""
   echo "   Retrieve latest ccollect at http://linux.schottelius.org/ccollect/."
   echo ""
   echo "   Version: $VERSION ($RELEASE, Grey Sunday Release)"
   exit 0
}

#
# need at least intervall and one source or --all
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
INTERVALL=$1; shift
i=1
no_shares=0

while [ $i -le $# ]; do
   eval arg=\$$i
   
   if [ "$NO_MORE_ARGS" = 1 ]; then
        eval share_${no_shares}=\"$arg\"
        no_shares=$(($no_shares+1))
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
            eval share_${no_shares}=\"$arg\"
            no_shares=$(($no_shares+1))
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
# Look, if we should take ALL sources
#
if [ "$ALL" = 1 ]; then
   # reset everything specified before
   no_shares=0
   
   #
   # get entries from sources
   #
   cwd=$(pwd)
   cd "$CSOURCES";
   ls > "$TMP"
   
   while read tmp; do
      eval share_${no_shares}=\"$tmp\"
      no_shares=$(($no_shares+1))
   done < "$TMP"
fi

#
# Need at least ONE source to backup
#
if [ "$no_shares" -lt 1 ]; then
   usage   
else
   echo "==> $WE: Beginning backup using intervall $INTERVALL <=="
fi

#
# check default configuration
#

D_FILE_INTERVALL="$CDEFAULTS/intervalls/$INTERVALL"
D_INTERVALL=$(cat $D_FILE_INTERVALL 2>/dev/null)

#
# Look for pre-exec command (general)
#
if [ -x "$CPREEXEC" ]; then
   echo "Executing $CPREEXEC ..."
   "$CPREEXEC"
   echo "Finished ${CPREEXEC}."
fi

#
# Let's do the backup
#
i=0
while [ "$i" -lt "$no_shares" ]; do

   #
   # Get current share
   #
   eval name=\$share_${i}
   i=$(($i+1))

   export name

   #
   # start ourself, if we want parallel execution
   #
   if [ "$PARALLEL" ]; then
      $0 "$INTERVALL" "$name" &
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

   c_pre_exec="$backup/pre_exec"
   c_post_exec="$backup/post_exec"

   echo "Beginning to backup this source ..."

   #
   # Standard configuration checks
   #
   if [ ! -e "$backup" ]; then
      echo "Source does not exist."
      exit 1
   fi
   if [ ! -d "$backup" ]; then
      echo "\"$name\" is not a cconfig-directory. Skipping."
      exit 1
   fi

   #
   # intervall definition: First try source specific, fallback to default
   #
   c_intervall="$(cat "$backup/intervalls/$INTERVALL" 2>/dev/null)"

   if [ -z "$c_intervall" ]; then
      c_intervall=$D_INTERVALL

      if [ -z "$c_intervall" ]; then
         echo "Default and source specific intervall missing. Skipping."
         exit 1
      fi
   fi

   #
   # standard rsync options
   #
   VERBOSE=""
   VVERBOSE=""
   EXCLUDE=""
   RSYNC_EXTRA=""

   #
   # next configuration checks
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

   if [ ! -d "$c_dest" ]; then
      echo "Destination $c_dest does not link to a directory. Skipping"
      exit 1
   fi
   
   #
   # pre_exec
   #
   if [ -x "$c_pre_exec" ]; then
      echo "Executing $c_pre_exec ..."
      $c_pre_exec
      echo "Finished ${c_pre_exec}."
   fi
   
   # exclude
   if [ -f "$c_exclude" ]; then
      EXCLUDE="--exclude-from=$c_exclude"
   fi
   
   # extra options for rsync
   if [ -f "$c_rsync_extra" ]; then
      RSYNC_EXTRA="$(cat "$c_rsync_extra")"
   fi
   
   # verbosity for rsync
   if [ -f "$c_verbose" ]; then
      VERBOSE="-v"
   fi
   
   # MORE verbosity, includes standard verbosity
   if [ -f "$c_vverbose" ]; then
      VERBOSE="-v"
      VVERBOSE="-v"
   fi
   
   #
   # check if maximum number of backups is reached, if so remove
   #
   
   # the created directories are named $INTERVALL.$DA
   count=$(ls -d "$c_dest/${INTERVALL}."?*  2>/dev/null | wc -l)
   echo "Currently $count backup(s) exist, total keeping $c_intervall backup(s)."
   
   if [ "$count" -ge "$c_intervall" ]; then
      substract=$(echo $c_intervall - 1 | bc)
      remove=$(echo $count - $substract | bc)
      echo "Removing $remove backup(s)..."

      ls -d "$c_dest/${INTERVALL}."?* | sort -n | head -n $remove > "$TMP"
      while read to_remove; do
         dir="$to_remove"
         echo "Removing $dir ..."
         rm $VVERBOSE -rf "$dir"
      done < "$TMP"
   fi
   
   #
   # clone the old directory with hardlinks
   #

   destination_date=$(date +%Y-%m-%d-%H:%M)
   destination_dir="$c_dest/${INTERVALL}.${destination_date}.$$"
   
   last_dir=$(ls -d "$c_dest/${INTERVALL}."?* 2>/dev/null | sort -n | tail -n 1)
   
   # give some info
   echo "Beginning to backup, this may take some time..."

   # only copy if a directory exists
   if [ "$last_dir" ]; then
      echo "Hard linking..."
      cp -al $VVERBOSE "$last_dir" "$destination_dir"
   else
      echo "Creating $destination_dir"
      mkdir $VVERBOSE "$destination_dir"
   fi

   if [ $? -ne 0 ]; then
      echo "Creating/cloning backup directory failed. Skipping backup."
      exit 1
   fi

   #
   # the rsync part
   # options partly stolen from rsnapshot
   #
   
   echo "Transferring files..."

   rsync -a $VERBOSE $RSYNC_EXTRA $EXCLUDE \
      --delete --numeric-ids --relative --delete-excluded \
      "$source" "$destination_dir"
   
   if [ "$?" -ne 0 ]; then
      echo "rsync failed, backup may be broken (see rsync errors)"
      exit 1
   fi

   echo "Successfully finished backup."

   #
   # post_exec
   #
   if [ -x "$c_post_exec" ]; then
      echo "Executing $c_post_exec ..."
      "$c_post_exec"
      echo "Finished ${c_post_exec}."
   fi

) | add_name
done

#
# Be a good parent and wait for our children, if they are running wild parallel
#
if [ "$PARALLEL" ]; then
   echo "Waiting for child jobs to complete..."
   wait
fi

#
# Look for post-exec command (general)
#
if [ -x "$CPOSTEXEC" ]; then
   echo "Executing $CPOSTEXEC ..."
   "$CPOSTEXEC"
   echo "Finished ${CPOSTEXEC}."
fi

rm -f "$TMP"
echo "==> Finished $WE <=="

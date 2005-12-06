#!/bin/sh
# Nico Schottelius
# written for SyGroup (www.sygroup.ch)
# Date: Mon Nov 14 11:45:11 CET 2005
# Last Modified: 


#
# temporary as long as inofficial
#
CCOLLECT_CONF=$HOME/crsnapshot/conf


#
# where to find our configuration and temporary file
#
CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
CSOURCES=$CCOLLECT_CONF/sources
CDEFAULTS=$CCOLLECT_CONF/defaults
TMP=$(mktemp /tmp/$(basename $0).XXXXXX)


#
# catch signals
#
trap "rm -f \"$TMP\"" 1 2 15


#
# errors!
#
errecho()
{
   echo "Error: $@" >&2
}


#
# Tell how to use us
#
usage()
{
   echo "$(basename $0): [args] <intervall name> <sources to backup>"
   echo ""
   echo "   Nico Schottelius (nico-linux-ccollect schottelius.org) - 2005-12-06"
   echo ""
   echo "   Backup data pseudo incremental"
   echo ""
   echo "   -h, --help:          Show this help screen"
   echo "   -p, --parallel:      Parellize backup process"
   echo "   -a, --all:           Backup all sources specified in $CSOURCES"
   echo ""
   echo "   Retrieve latest ccollect at http://linux.schottelius.org/ccollect/."
   echo ""
   exit 0
}


#
# Filter arguments
#
i=1
no_shares=0

while [ $i -le $# ]; do
   eval arg=\$$i
   
   if [ "$NO_MORE_ARGS" = 1 ]; then
        eval share_${no_shares}="$arg"
        no_shares=$((no_shares+1))
   else
      case $arg in
         -a|--all)
            ALL=1
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
            eval share_${no_shares}="$arg"
            no_shares=$((no_shares+1))
            ;;
      esac
   fi

   i=$((i+1))
done


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
   cd $CSOURCES;
   ls > "$TMP"
   
   while read tmp; do
      eval share_${no_shares}=\"$tmp\"
      no_shares=$((no_shares+1))
   done < "$TMP"
fi

#
# Need at least ONE source to backup
#
if [ "$no_shares" -lt 1 ]; then
   usage   
fi

#
# Let's do the backup
#
i=0
while [ "$i" -lt "$no_shares" ]; do

   #
   # Standard locations
   #
   eval name=\$share_${i}
   backup="$CSOURCES/$name"
   c_source="$backup/source"
   c_dest="$backup/destination"
   c_exclude="$backup/exclude"

   #
   # standard rsync options
   #
   VERBOSE=""
   EXCLUDE=""

   i=$((i+1))

   echo "Beginning to backup \"$name\" ..."
   
   #
   # Standard configuration checks
   #
   if [ ! -d "$backup" ]; then
      errecho "\"$name\" is not a cconfig-directory. Skipping."
      continue
   fi

   if [ ! -f "$c_source" ]; then
      echo "Source description $c_source is not a file. Skipping."
      continue
   else
      source=$(cat "$c_source")
      if [ $? -ne 0 ]; then
         echo "Skipping: Source $c_source is not readable"
         continue
      fi
   fi

   if [ ! -d "$c_dest" ]; then
      errecho "Destination $c_dest does not link to a directory. Skipping"
      continue
   fi

   if [ -f "$c_exclude" ]; then
      errecho "Destination $c_dest does not link to a directory. Skipping."
      continue
   
      while read tmp; do
         EXCLUDE="$EXCLUDE --exclude \"$tmp\""
     done < "$c_exclude"
   fi

   #
   # clone the old directory with hardlinks
   #

   #
   # the rsync part
   #
   echo rsync --delete $VERBOSE $EXCLUDE
done

#
# Be a good parent and wait for our children, if they are running wild parallel
#
if [ "$PARALLEL" = 1 ]; then
   wait
fi

rm -f "$TMP"

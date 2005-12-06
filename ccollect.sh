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
# where to find our configuration
#
CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
CSOURCES=$CCOLLECT_CONF/sources/
CDEFAULTS=$CCOLLECT_CONF/defaults/

#
# Tell how to use us
#
usage()
{
   echo "$(basename $0): [args] <sources to backup>"
   echo ""
   echo "   Nico Schottelius (nico-linux-ccollect schottelius.org) - 2005-12-06"
   echo ""
   echo "   Backup data pseudo incremental"
   echo ""
   echo "   -h, --help:          Show this help screen"
   echo "   -p, --parallel:      Parellize backup process"
   echo "   -a, --all:           Backup all sources specified in $CSOURCES"
   echo ""
   echo "   http://linux.schottelius.org/ccollect/"
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
         -v|--verbose)
            VERBOSE=1
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

   OLD_IFS=$IFS
   export IFS=\\n

   for tmp in $(cd $CSOURCES/; ls); do
      eval share_${no_shares}="$tmp"
      no_shares=$((no_shares+1))
      echo \"-${tmp}-\"
   done
fi

#
# Need at least ONE source to backup
#
if [ "$no_shares" -lt 1 ]; then
   usage   
fi


exit 1

if [ -z "$(ls $CCOLLECT_CONF 2>/dev/null)" ]; then
   echo "Aborting, nothing specified to backup in $CCOLLECT_CONF"
   exit 23
fi

for backup in $CCOLLECT_CONF/*; do
   #
   # Standard locations
   #

   c_source="$backup/source"
   c_dest="$backup/destination"
   c_exclude="$backup/exclude"
   
   #
   # Standard configuration checks
   #
   if [ ! -d "$backup" ]; then
      echo "Ignoring $backup, is not a directory"
      continue
   fi
   
   if [ ! -f "$c_source" ]; then
      echo "Skipping: Source $c_source is not a file"
      continue
   else
      source=$(cat $c_source)
      if [ $? -ne 0 ]; then
         echo "Skipping: Source $c_source is not readable"
         continue
      fi
   fi
   
   if [ ! -d "$c_dest" ]; then
      echo "Skipping: Destination $c_dest does not link to a directory"
      continue
   fi

   if [ -f "$c_exclude" ]; then
      echo "Skipping: Destination $c_dest does not link to a directory"
      continue
   fi
   
done

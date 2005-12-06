#!/bin/sh
# Nico Schottelius
# written for SyGroup (www.sygroup.ch)
# Date: Mon Nov 14 11:45:11 CET 2005
# Last Modified: 


CCOLLECT_CONF=$HOME/crsnapshot/conf
CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}

#
# ARGV:
# -s|--silent
# -p|--parallel
# -v|--verbose
#

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

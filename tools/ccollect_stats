#!/bin/sh
#
# 2007 Daniel Aubry
# 2008 Nico Schottelius (added minimal header)
#
# Copying license: GPL2-only
#

# TODO:
# add variables, add copying, add configuration

if [ ! -e /tmp/ccollect-stats.lock ] 
then
   touch /tmp/ccollect-stats.lock

   # changes after license clearify
   #  for dest in /etc/ccollect/sources/ -type f -name destination | while read line

   find /etc/ccollect/sources/ -type l | while read line
   d=$(basename $(readlink $line))
      echo "====[Backup: $backupname]====" | tee -a /var/log/backup.log
      du -sh $line/* | tee -a /var/log/backup.log
   done
   rm /tmp/ccollect-stats.lock
fi

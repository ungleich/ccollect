#!/bin/sh


if [ ! -e /tmp/ccollect-stats.lock ] 
then
	touch /tmp/ccollect-stats.lock
	find /etc/ccollect/sources/ -type l | while read line
	do
		backupname=$(basename $(readlink $line))
		echo "====[Backup: $backupname]====" | tee -a /var/log/backup.log
		du -sh $line/* | tee -a /var/log/backup.log
	done
	rm /tmp/ccollect-stats.lock
fi




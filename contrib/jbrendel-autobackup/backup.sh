#!/bin/bash 

function mkbackup {
    find /etc/ccollect/logwrapper/destination -type f -atime +2 -exec sudo rm {} \;
    /home/jcb/bm.pl &
}

mkdir -p /media/backupdisk
grep backupdisk /etc/mtab &> /dev/null

if [ $? == 0 ]
then
	mkbackup
else
    mount /media/backupdisk
    if [ $? == 0 ]
    then
	mkbackup
    else
        echo "Error mounting backup disk"	
    fi
fi

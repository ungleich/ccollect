#!/bin/sh
#
# Nico Schottelius <nico-linux //@// schottelius.org>
# Date: 27-Jan-2007
# Last Modified: -
# Description:
#

ccollect=../ccollect.sh
testdir="$(dirname $0)/test-backups"
confdir="$(dirname $0)/test-config"
source="$(hostname)"
source_source="/tmp"
interval="taeglich"


# backup destination
mkdir -p "$testdir"
source_dest="$(cd "$testdir"; pwd -P)"

# configuration
mkdir -p "${confdir}/sources/${source}"
ln -s "$source_dest" "${confdir}/sources/${source}/destination"
echo "$source_source" > "${confdir}/sources/${source}/source"
touch "${confdir}/sources/${source}/summary"
touch "${confdir}/sources/${source}/verbose"

mkdir -p "${confdir}/defaults/intervals/"
echo 3 > "${confdir}/defaults/intervals/$interval"

# create backups

CCOLLECT_CONF="$confdir" "$ccollect" "$interval" -p -a
touch "${source_source}/$(date +%s)-$$.1982"

CCOLLECT_CONF="$confdir" "$ccollect" "$interval" -p -a
touch "${source_source}/$(date +%s)-$$.42"

CCOLLECT_CONF="$confdir" "$ccollect" "$interval" -p -a

du -sh   "$testdir"
du -shl  "$testdir"

echo "Delete $testdir and $confdir after test"

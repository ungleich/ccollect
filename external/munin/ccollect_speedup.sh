#!/bin/sh
# Nico Schottelius
# 2007-10-02
# speedup

CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
CSOURCES=${CCOLLECT_CONF}/sources
CCOLLECT_LOGDIR=${CCOLLECT_LOGDIR:-/var/log/backup}
LOGFILE=$(cd "${CCOLLECT_LOGDIR}" && ls -tcp1 | grep '/$' | head -n 1)



case "$1" in
   config)
cat << eof
graph_title Backups speedup
graph_category backup
graph_vlabel speedup
eof
# create labels
cd "${CSOURCES}"
for source in *; do
   name="_$(echo $source | sed 's/\./_/g')"
   echo ${name}.label ${source}
done



      exit 0
   ;;
esac

# get values
cd "${CSOURCES}"
for source in *; do
   name="_$(echo $source | sed 's/\./_/g')"
   awk "/^\[${source}\] total size is/ { print \$8 }" "${LOGFILE}"
done

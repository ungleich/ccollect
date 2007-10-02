#!/bin/sh
# Nico Schottelius
# 2007-10-02
# How much bytes transferred

CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
CSOURCES=${CCOLLECT_CONF}/sources
CCOLLECT_LOGDIR=${CCOLLECT_LOGDIR:-/var/log/backup}
latest_log=$(cd "${CCOLLECT_LOGDIR}" && ls -tcp1 | grep -v '/$' | head -n 1)
LOGFILE="${CCOLLECT_LOGDIR}/${latest_log}"

case "$1" in
   config)
cat << eof
graph_title ccollect recieved bytes
graph_category backup
graph_vlabel Bytes
graph_info Shows how much data ccollect recieved for each server (0 means no value found)
timeout 30
graph_args --base 1024
eof
# create labels
cd "${CSOURCES}"
for source in *; do
   name="_$(echo $source | sed 's/\./_/g')"
   echo ${name}.label ${source}
   echo ${name}.min 0
done
      exit 0
   ;;
esac

# get values
cd "${CSOURCES}"
for source in *; do
   name="_$(echo $source | sed 's/\./_/g')"
   value="$(awk "/^\[${source}\] Total bytes received: / { print \$5 }" < "${LOGFILE}")"
   # value = 0 = no result found
   [ "$value" ] || value=0
   echo ${name}.value "${value}"
done

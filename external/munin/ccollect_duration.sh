#!/bin/sh
# Nico Schottelius
# 2007-10-02
# speedup

CCOLLECT_CONF=${CCOLLECT_CONF:-/etc/ccollect}
CSOURCES=${CCOLLECT_CONF}/sources
CCOLLECT_LOGDIR=${CCOLLECT_LOGDIR:-/var/log/backup}
latest_log=$(cd "${CCOLLECT_LOGDIR}" && ls -tcp1 | grep -v '/$' | head -n 1)
LOGFILE="${CCOLLECT_LOGDIR}/${latest_log}"

case "$1" in
   config)
cat << eof
graph_title ccollect backup duration
graph_category backup
graph_vlabel time in seconds
graph_info Shows the time needed by each source
timeout 30
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
   value_raw="$(awk "/^\[${source}\] Backup lasted: / { print \$4 }" < "${LOGFILE}")"
   value="$(echo $value_raw | awk -F: '{ print $1 *3600 + $2 * 60 +  $3 }')"
   # value = 0 = no result found
   [ "$value" ] || value=U
   echo ${name}.value "${value}"
done

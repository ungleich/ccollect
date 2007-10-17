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
graph_title ccollect Backup Exit Codes
graph_category backup
graph_vlabel Exit Code
graph_info Shows the exit codes
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
   value=$(awk "/^\[${source}\].*Finished backup \(rsync return code:/ { print \$8 }" "${LOGFILE}" | sed 's/)\.$//')
   # no value = U = unknown.
   [ "$value" ] || value=U
   echo ${name}.value "${value}"
done

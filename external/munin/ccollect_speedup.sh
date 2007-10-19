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
graph_title ccollect Backups speedup
graph_category backup
graph_vlabel speedup
graph_info Shows the speedup of ccollect backups (higher means better, zero means no value found)
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

# SPEEDUP!
set --
me=${0##*/}
tmp="$(mktemp /tmp/${me}.XXXXXXXXXXXXX)"
cd "${CSOURCES}"
for source in *; do
   term="^\[${source}\] total size is"
   set -- "$@" -e "${term}"
done

grep "$@" "${LOGFILE}" > "${tmp}"

# get values
cd "${CSOURCES}"
for source in *; do
   name="_$(echo $source | sed 's/\./_/g')"
   value=$(awk "/^\[${source}\] total size is/ { print \$8 }" "${tmp}")
   # value = 0 = no result found
   [ "$value" ] || value=U
   echo ${name}.value "${value}"
done

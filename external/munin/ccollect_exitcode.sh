#!/bin/sh
# Nico Schottelius
# 2007-10-02
# exit codes

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

# unset $@ and $#
set --

# tmpfile
me=${0##*/}
tmp="$(mktemp /tmp/${me}.XXXXXXXXXXXXX)"

# construct parameters for grep
cd "${CSOURCES}"
for source in *; do
   term="^\[${source}\].*Finished backup (rsync return code:"
   set -- "$@" -e "${term}"
done

grep "$@" "${LOGFILE}" > "${tmp}"

# get values
for source in *; do
   name="_$(echo $source | sed 's/\./_/g')"
   value=$(awk "/^\[${source}\]/ { print \$8 }" "${tmp}" | sed 's/).$//')
   # no value = U = unknown.
   [ "$value" ] || value=U
   echo ${name}.value "${value}"
done

rm -f "${tmp}"

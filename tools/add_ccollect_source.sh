#!/bin/sh
# Nico Schottelius
# 2007-08-16
# Written for Netstream (www.netstream.ch)
# Creates a source from standard values specified in
# /etc/ccollect/defaults/sources
# Copying: GPLv3

# standard values
CCOLLECT_CONF="${CCOLLECT_CONF:-/etc/ccollect}"
CSOURCES="${CCOLLECT_CONF}/sources"
CDEFAULTS="${CCOLLECT_CONF}/defaults"
SCONFIG="${CDEFAULTS}/sources"

# standard options: variable2filename
exclude="exclude"
summary="summary"
intervals="intervals"
pre_exec="pre_exec"
post_exec="post_exec"
rsync_options="rsync_options"
verbose="verbose"
very_verbose="very_verbose"

# options that we simply copy over
standard_opts="exclude summary intervals pre_exec post_exec rsync_options verbose very_verbose"

# options not in standard ccollect, used only for source generation
src_prefix="${SCONFIG}/source_prefix"
src_postfix="${SCONFIG}/source_postfix"
destination_base="${SCONFIG}/destination_base"

self="$(basename $0)"

# functions first
_echo()
{
   echo "${self}> $@"
}

_exit_err()
{
   _echo "$@"
   rm -f "$TMP"
   exit 1
}

# argv
if [ $# -lt 1 ]; then
   _exit_err "<hostnames to create sources for>"
fi

_echo "Reading defaults from ${SCONFIG} ..."

while [ $# -gt 0 ]; do
   source="$1"; shift

   # Create
   _echo "Creating ${source} ..."

   fullname="${CSOURCES}/${source}"

   # create source
   if [ -e "${fullname}" ]; then
      _echo "${fullname} already exists. Skipping."
      continue
   fi
   mkdir -p "${fullname}" || _exit_err Cannot create \"${fullname}\".

   # copy standard files
   for file in $standard_opts; do
      eval rfile=\"\$$file\"
      eval filename=${SCONFIG}/${rfile}
      if [ -e "${filename}" ]; then
         _echo Copying \"$rfile\" to ${fullname} ...
         cp -r "${filename}" "${fullname}/${rfile}"
      fi
   done

   # create source entry
   if [ -f "${src_prefix}" ]; then
      source_source="$(cat "${src_prefix}")" || _exit_err "${src_prefix}: Reading failed."
   fi
   source_source="${source_source}${source}"
   if [ -f "${src_postfix}" ]; then
      source_source="${source_source}$(cat "${src_postfix}")" || _exit_err "${src_postfix}: Reading failed."
   fi
   _echo "Adding \"${source_source}\" as source for ${source}"
   echo "${source_source}" > "${fullname}/source"

   # create destination directory
   dest="${destination_base}/${source}"
   _echo "Creating destination ${dest} ..."
   mkdir -p "${dest}" || _exit_err "${dest}: Cannot create."

   # link destination directory
   dest_abs=$(cd "${dest}" && pwd -P) || _exit_err "${dest}: Changing to newly create dirctory failed."
   ln -s "${dest_abs}" "${fullname}/destination" || \
      _exit_err "${fullname}/destination: Failed to link \"${dest_abs}\""

done

exit 0

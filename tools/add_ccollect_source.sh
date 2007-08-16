#!/bin/sh
# Nico Schottelius
# 2007-08-16
# Written for Netstream (www.netstream.ch)
# Creates a source from standard values specified in
# /etc/ccollect/defaults/sources

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
      echo r: $rfile
      eval filename=${SCONFIG}/${rfile}
      echo f: $filename
      if [ -e "${filename}" ]; then
         _echo Copying $rfile for $source ...
         cp -r "${filename}" "${fullname}/${rfile}"
      fi
   done

   # create source entry
   if [ -f "${src_prefix}" ]; then
      source_source="$(cat "${src_prefix}")" || _exit_err "Reading $src_prefix failed."
   fi
   source_source="${source_source}${source}"
   if [ -f "${src_postfix}" ]; then
      source_source="${source_source}$(cat "${src_postfix}")" || _exit_err "Reading $src_postfix failed."
   fi
   _echo "Adding ${source_source} as source for ${source}"
   echo "${source_source}" > "${fullname}/source"

   # create destination directory
   dest="${destination_base}/${source}"
   _echo "Creating destination ${dest} ..."
   mkdir -p "${dest}" || _exit_err "${fullname}: Cannot create ${dest}."

done


exit 0



echo "root@${source}:/" > "${fullname}/source"
cat << eof > "${fullname}/exclude" || exit 4
/dev/*
/proc/*
/tmp/*
eof

# Destination
if [ -e "${destination}" ]; then
   if [ ! -d "${destination}" ]; then
      echo "${destination} exists, but is not a directory. Aborting."
      exit 5
   fi
else
   _echo "Creating ${destination} ..."
   mkdir -p "${destination}" || _exit_err "Failed to create ${destination}."
fi

ln -s "${destination}" "${fullname}/destination" || \
   _exit_err "Failed to link \"${destination}\" to \"${fullname}/destination\""

# finish
_echo "Added some default values, please verify \"${fullname}\"."
_echo "Finished."

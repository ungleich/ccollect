#!/bin/sh
# 
# 2008      Nico Schottelius (nico-ccollect at schottelius.org)
# 
# This file is part of ccollect.
#
# ccollect is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ccollect is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with ccollect. If not, see <http://www.gnu.org/licenses/>.
#

################################################################################
# standard vars stolen from cconf
__pwd="$(pwd -P)"
__mydir="${0%/*}"; __abs_mydir="$(cd "$__mydir" && pwd -P)"
__myname=${0##*/}; __abs_myname="$__abs_mydir/$__myname"


################################################################################
# ccollect standard vars
CCOLLECT_CONF="${CCOLLECT_CONF:-/etc/ccollect}"
CDEFAULTS="${CCOLLECT_CONF}/defaults"
CLOGDIR="${CDEFAULTS}/logdir"
CRONTAB="${CRONTAB:-/etc/crontab}"

# Parameters:
# -c, --crontab
# -f, --fix
# -l, --logs



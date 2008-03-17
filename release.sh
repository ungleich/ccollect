#!/bin/sh
# 
# 200?-2008 Nico Schottelius (nico-ccollect at schottelius.org)
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
# Standard release script for dummies like me
#

if [ $# -ne 1 ]; then
   echo "$0: ccollect dir"
   exit 23
fi

echo "Did you change version and date information in the script?"
read bla

NAME=$1
TARNAME=${NAME}.tar.bz2

DHOST=nico@home.schottelius.org
DDIR=www/org/schottelius/unix/www/ccollect/
DESTINATION="$DHOST:$DDIR"

# create documentation for the end user
(
   cd "$NAME"
   make dist
   make publish-doc
)

tar cvfj "$TARNAME" \
   --exclude=.git \
   --exclude="conf/sources/*/destination/*" "$NAME"

scp "${TARNAME}" "$DESTINATION"

ssh "$DHOST" "( cd $DDIR; tar xfj \"$TARNAME\" )"

echo "setting paranoid permissions to public..."
ssh "$DHOST" "( cd $DDIR; find -type d -exec chmod 0755 {} \; )"
ssh "$DHOST" "( cd $DDIR; find -type f -exec chmod 0644 {} \; )"

cat "${NAME}/doc/release-checklist"

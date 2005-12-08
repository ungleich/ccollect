NAME=$1
TARNAME=${NAME}.tar.bz2

DHOST=nico@creme.schottelius.org
DDIR=www/org/schottelius/linux/ccollect/
DESTINATION="$DHOST:$DDIR"

tar cvfj "$TARNAME"
   --exclude=.git \
   --exclude="conf/sources/*/destination/*" \
   "$NAME"

scp "${TARNAME}" "$DESTINATION"

ssh "$DHOST" "( cd $DDIR; tar xfj \"$TARNAME\" )"

NAME=$1

tar cvfj ${NAME}.tar.bz2  \
   --exclude=.git \
   --exclude="conf/sources/*/destination/*" \
   "$NAME"

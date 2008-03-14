#!/bin/sh

host="home.schottelius.org"
host=""
set -x
pcmd()
{
   echo "$#", "$@"
   if [ "$host" ]; then
      ssh "$host" "$@"
   else
      $@
   fi
}

#pcmd ls /
#pcmd cd /; ls "/is not there"
pcmd cd / && ls

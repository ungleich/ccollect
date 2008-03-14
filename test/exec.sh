#!/bin/sh

host="home.schottelius.org"

pcmd()
{
   if [ "$host" ]; then
      ssh "$host" "$@"
   else
      "$@"
   fi
}

pcmd ls /
pcmd cd /; ls "/is not there"

#!/bin/sh

ls /surely-not-existent$$ 2>/dev/null

if [ "$?" -ne 0 ]; then
   echo "$?"
fi

ls /surely-not-existent$$ 2>/dev/null

ret=$?

if [ "$ret" -ne 0 ]; then
   echo "$ret"
fi


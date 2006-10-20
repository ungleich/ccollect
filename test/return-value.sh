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

# if is true, ls is fales
if [ "foo" = "foo" ]; then
   ls /surely-not-existent$$ 2>/dev/null
fi

# but that's still the return of ls and not of fi
echo $?

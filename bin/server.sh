#!/bin/bash

# Usage: socat UNIX-LISTEN:/tmp/submarine.sock,reuseaddr,fork EXEC:/app.sh,fdin=3,fdout=4
# FD 3 = incoming traffic
# FD 4 = traffic sent back to the client

# Process the received HTTP headers
request_file="/tmp/$RANDOM$$"
while read -u 3 -r line; do
  echo "$line"
  [[ -z $line ]] && break
done > $request_file

request_verb="$(cat $request_file | head -1 | awk '{print $1}')"
request_path="$(cat $request_file | head -1 | awk '{print $2}')"
rm -f $request_file

# Send HTTP response
cat <<END4 >&4
HTTP/1.1 200 OK
Date: $(date)
Server: Submarine

<html>
<body>
  VERB=$request_verb
  PATH=$request_path
</body>
</html>
END4

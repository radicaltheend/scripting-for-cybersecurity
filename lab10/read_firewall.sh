#!/bin/bash

count22=0
count80=0
count443=0
count3389=0

while read -r ACTION SRC ARROW DST; do
    PORT=${DST##*:}
    if [ "$ACTION" = "BLOCK" ]; then
        echo "$ACTION from $SRC to port $PORT"

        if [ "$PORT" = "22" ]; then
            count22=$((count22 + 1))
        elif [ "$PORT" = "80" ]; then
            count80=$((count80 + 1))
        elif [ "$PORT" = "443" ]; then
            count443=$((count443 + 1))
        elif [ "$PORT" = "3389" ]; then
            count3389=$((count3389 + 1))
        fi
    fi
done < case/logs/firewall.log

echo
echo "Blocked connections per port:"
echo "Port 22:   $count22"
echo "Port 80:   $count80"
echo "Port 443:  $count443"
echo "Port 3389: $count3389"

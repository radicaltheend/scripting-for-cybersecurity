#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Empty"
	exit 1
fi

if [ ! -f "$1" ]; then
	echo "Not a file"
	exit 2
fi

FAILED=$(grep -c "Failed password" "$1")
TOP=$(grep "Failed password" "$1" | awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | sort | uniq -c | sort -nr | head -n 1)
TOP_ATTACKERS=$(grep "Failed password" "$1" | awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | sort | uniq -c | sort -nr | head -n 3)
USER=$(grep "Failed password" "$1" | awk '{for(i=1;i<=NF;i++) if($i=="for") print $(i+1)}' | sort | uniq -c | sort -nr | head -n 3| awk '{print $2}')
echo $FAILED
echo $TOP
echo $TOP_ATTACKERS
echo $USER
exit 0


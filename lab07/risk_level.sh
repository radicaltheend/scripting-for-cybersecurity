#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <failed_attempt_count>" >&2
    exit 1
fi

COUNT=$1

if [ "$COUNT" -eq 0 ]; then
    echo "Risk: NONE (no failed attempts)"
elif [ "$COUNT" -lt 5 ]; then
    echo "Risk: LOW ($COUNT failed attempts)"
elif [ "$COUNT" -lt 15 ]; then
    echo "Risk: MEDIUM ($COUNT failed attempts)"
elif [ "$COUNT" -gt 14 ] &&  [ "$COUNT" -lt 30 ]; then
    echo "Risk: HIGH ($COUNT failed attempts)"
else
     echo "Risk: CRITICAL ($COUNT failed attempts)"
fi

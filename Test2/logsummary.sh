#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <logfile>"
    exit 1
fi

LOGFILE=$1

if [ ! -f "$LOGFILE" ]; then
    echo "Error: file '$LOGFILE' not found"
    exit 2
fi

if [ ! -s "$LOGFILE" ]; then
    echo "Error: file '$LOGFILE' is empty" 
    exit 3
fi

LINE_COUNT=$(wc -l < "$LOGFILE")
FAILED=$(grep -c "Failed password" "$LOGFILE")
ACCEPTED=$(grep -c "Accepted password" "$LOGFILE")
FIRST_LINE=$(head -n 1 "$LOGFILE" | awk '{print $1, $2, $3}')
LAST_LINE=$(tail -n 1 "$LOGFILE" | awk '{print $1, $2, $3}')

echo "File     : $LOGFILE"
echo "Lines    : $LINE_COUNT"
echo "Failed   : $FAILED"
echo "Accepted : $ACCEPTED"
echo "First    : $FIRST_LINE"
echo "Last     : $LAST_LINE"

exit 0

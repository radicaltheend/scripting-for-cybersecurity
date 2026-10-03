#!/bin/bash

# logstats.sh - print basic statistics for a log file
# Usage: ./logstats.sh <logfile>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <logfile>" >&2
    exit 1
fi

LOGFILE=$1

if [ ! -f "$LOGFILE" ]; then
    echo "Error: file '$LOGFILE' not found" >&2
    exit 2
fi

LINE_COUNT=$(wc -l < "$LOGFILE")
WORD_COUNT=$(wc -w < "$LOGFILE")
CHAR_COUNT=$(wc -c < "$LOGFILE")
FIRST_LINE=$(head -n 1 "$LOGFILE")
LAST_LINE=$(tail -n 1 "$LOGFILE")
BLOCK=$(grep -c "BLOCK" "$LOGFILE")
LONGEST_LINE=$(awk '{ print length }' "$LOGFILE" | sort -rn | head -n 1)
FAILED=$(grep -c "Failed password" "$LOGFILE")
echo "Log file        : $LOGFILE"
echo "Total lines     : $LINE_COUNT"
echo "Total words     : $WORD_COUNT"
echo "Total characters: $CHAR_COUNT"
echo "First line      : $FIRST_LINE"
echo "Last line       : $LAST_LINE"
echo "Longest line    : $LONGEST_LINE characters"
echo "Failed logins   : $FAILED"
echo "Blocked ips     : $BLOCK"
echo "$LOGFILE	     " "$LINE_COUNT	   " "$FAILED	" "$(echo "$FIRST_LINE	    " | cut -d" " -f3)" "$(echo "$LAST_LINE" | cut -d" " -f3)" >> investigation.txt

exit 0

#!/bin/bash

COUNT=0
TOTAL_LINES=0

while IFS= read -r -d '' LOGFILE; do
    COUNT=$((COUNT + 1))
    LINES=$(wc -l < "$LOGFILE")
    TOTAL_LINES=$((TOTAL_LINES + LINES))

    echo "$LOGFILE: $LINES lines"
done < <(find exam-data -type f -name "*.log" -print0)

echo "after the loop: $COUNT"
echo "Total lines: $TOTAL_LINES"

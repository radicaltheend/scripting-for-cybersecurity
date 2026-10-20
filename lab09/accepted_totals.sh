#!/bin/bash

TOTAL=0

for LOGFILE in case/logs/*.log; do
    COUNT=$(grep -c "Accepted password" "$LOGFILE")
    echo "$LOGFILE: $COUNT accepted logins"
    TOTAL=$((TOTAL + COUNT))
done

echo "TOTAL: $TOTAL"

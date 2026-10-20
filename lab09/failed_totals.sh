#!/bin/bash

TOTAL=0

for LOGFILE in case/logs/*.log; do
    COUNT=$(grep -c "Failed password" "$LOGFILE")
    echo "$LOGFILE: $COUNT failed logins"
    TOTAL=$((TOTAL + COUNT))
done

echo "TOTAL: $TOTAL"

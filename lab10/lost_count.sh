#!/bin/bash

COUNT=0
find case -type f -name "*.log" -print0 |
while IFS= read -r -d '' LOGFILE; do
    COUNT=$((COUNT + 1))
    echo "inside the loop: COUNT=$COUNT"
done
echo "after the loop:  COUNT=$COUNT"

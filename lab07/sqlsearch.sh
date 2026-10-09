#!/bin/bash

LOG="case/logs/access.log"

grep -q "sqlmap" "$LOG"
echo "Test"
if [ "$?" -eq 0 ]; then
    echo "DETECTED"
else
    echo "not detected"
fi

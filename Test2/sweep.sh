#!/bin/bash

TOTAL=0

for INDICATOR in $(cat exam-data/intel/iocs.txt); do
    SOURCES=0
    WHERE=""

    for LOGFILE in exam-data/case/logs/*.log; do
        if grep -qwF "$INDICATOR" "$LOGFILE"; then
            COUNT=$(grep -cwF "$INDICATOR" "$LOGFILE")
            echo "MATCH: $INDICATOR in $(basename "$LOGFILE") ($COUNT lines)"
            SOURCES=$((SOURCES + 1))
            WHERE="$WHERE $(basename "$LOGFILE")"
            TOTAL=$((TOTAL + COUNT))
        fi
    done

    echo "$INDICATOR: seen in $SOURCES log(s):$WHERE"
done

echo "Total matching lines: $TOTAL"

for FILE in exam-data/case/evidence/*; do
    [ -f "$FILE" ] || continue
    HASH=$(md5sum "$FILE" | awk '{print $1}')

    if grep -qxF "$HASH" exam-data/intel/iocs.txt; then
        echo "KNOWN BAD: $FILE"
    else
        echo "clean : $FILE"
    fi
done

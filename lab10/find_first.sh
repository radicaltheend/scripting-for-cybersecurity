#!/bin/bash

LOG="case/nested/archive/old.log"
none=1
while IFS= read -r INDICATOR; do
    if grep -qwF "$INDICATOR" "$LOG"; then
	none=0
        echo "First match in $LOG: $INDICATOR — stopping search."
        break
    fi
done < intel/iocs.txt

if [ "$none" -eq 1 ]; then
	echo "No matches founded"
fi
echo "Search finished."

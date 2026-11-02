#!/bin/bash

FIRST_LINE=1
ACTIVE=0
DISABLED=0

while IFS=',' read -r USERNAME ROLE STATUS DEPT; do
    if [ "$FIRST_LINE" -eq 1 ]; then
        FIRST_LINE=0
        continue
    fi

    DEPT=${DEPT%$'\r'}
    ACCEPTED=$(grep -cF "Accepted password for $USERNAME " exam-data/case/logs/auth.log)

    echo "$USERNAME | $ROLE | $STATUS | $DEPT | logins: $ACCEPTED"

    if [ "$STATUS" = "active" ]; then
        ACTIVE=$((ACTIVE + 1))
    elif [ "$STATUS" = "disabled" ]; then
        DISABLED=$((DISABLED + 1))

        if [ "$ACCEPTED" -gt 0 ]; then
            echo "ALERT: disabled account $USERNAME has accepted logins"
        fi
    fi
done < exam-data/intel/users.csv

echo "Active accounts: $ACTIVE"
echo "Disabled accounts: $DISABLED"

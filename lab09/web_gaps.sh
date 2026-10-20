#!/bin/bash

ATTACKERS=$(awk '{print $1}' case/logs/access.log | sort -u)

for IP in $ATTACKERS; do
    COUNT=$(grep -c "Failed password.* from $IP " case/logs/auth.log)
    if grep -qxF "$IP" intel/iocs.txt; then
        echo "$IP ($COUNT failures): already in IOC list"
    else
        echo "$IP ($COUNT failures): NOT in IOC list — candidate for new indicator"
    fi
done

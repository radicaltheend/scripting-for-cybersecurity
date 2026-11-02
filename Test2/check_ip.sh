#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <ip_address>"
    exit 1
fi

IP=$1

if ! echo "$IP" | grep -Eq '^[0-9]+(\.[0-9]+){3}$'; then
    echo "Error: enter an IPv4 address"
    exit 1
fi

LOG_DIR="exam-data/case/logs"
AUTH_LOG="$LOG_DIR/auth.log"
FIREWALL_LOG="$LOG_DIR/firewall.log"
IOC_FILE="exam-data/intel/iocs.txt"

FAILED=$(grep -F "Failed password" "$AUTH_LOG" | grep -Fc "$IP ")
ACCEPTED=$(grep -F "Accepted password" "$AUTH_LOG" | grep -Fc "$IP ")

echo "IP       : $IP"
echo "Failed   : $FAILED"
echo "Accepted : $ACCEPTED"

if [ "$FAILED" -eq 0 ]; then
    echo "Risk     : NONE"
elif [ "$FAILED" -lt 5 ]; then
    echo "Risk     : LOW"
elif [ "$FAILED" -lt 10 ]; then
    echo "Risk     : MEDIUM"
else
    echo "Risk     : HIGH"
fi

if grep -qxF "$IP" "$IOC_FILE"; then
    echo "IOC : yes"
else
    echo "IOC : no"
fi

if grep -qwF "$IP" "$FIREWALL_LOG"; then
    grep -wF "$IP" "$FIREWALL_LOG"
else
    echo "Firewall : no entries"
fi

if [ "$FAILED" -gt 0 ] && [ "$ACCEPTED" -gt 0 ]; then
    echo "WARNING: successful login after failed attempts"
fi

if grep -qwF "$IP" "$LOG_DIR"/*; then
    exit 0
else
    exit 3
fi

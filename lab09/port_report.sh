#!/bin/bash

REPORT=""

for CONF in case/configs/*.conf case/config-old.txt; do
    PORT=$(grep '^port=' "$CONF" | cut -d'=' -f2)
    DEBUG=$(grep '^debug=' "$CONF" | cut -d'=' -f2)
    if [ -z "$PORT" ]; then
        PORT="(none)"
    fi
    if [ -z "$DEBUG" ]; then
        DEBUG="(none)"
    fi
    REPORT="${REPORT}${CONF}: port ${PORT} debug ${DEBUG}"$'\n'
done

echo "Configured ports:"
echo "$REPORT"

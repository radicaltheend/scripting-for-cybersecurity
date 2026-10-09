#!/bin/bash

CONF=$1
DEBUG=$(grep 'tls=' "$CONF" | cut -d'=' -f2)

if [ -z "$DEBUG" ]; then
    echo "$CONF: no tls setting"
elif [ "$DEBUG" = "true" ]; then
    echo "$CONF: WARNING - tls mode is ON"
elif [ "$DEBUG" = "false" ]; then
    echo "$CONF: tls mode is off"
else
    echo "$CONF: unexpected debug value '$DEBUG'"
fi

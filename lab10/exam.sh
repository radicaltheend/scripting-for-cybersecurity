#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Error: expected exactly one argument. Usage: $0 <IPv4 address>" >&2
    exit 1
fi

ip="$1"

if ! [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: '$ip" does not look like an IPv4 address." >&2
    exit 1
fi

echo "Investigating $ip"

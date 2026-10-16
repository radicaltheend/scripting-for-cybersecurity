#!/bin/bash

FILE=$1

if [ -z "$FILE" ]; then
    echo "Usage: $0 <file>" >&2
    exit 1
fi

if [ -f "$FILE" ]; then
	echo "$FILE is a file" > /dev/null
else
	echo "$FILE is not a file"
	exit 2
fi
if [ -r "$FILE" ]; then
        echo "$FILE is readable" > /dev/null
else
        echo "$FILE is not readable "
        exit 3
fi
if [ -s "$FILE" ]; then
        echo "$FILE is not empty" > /dev/null
else
        echo "$FILE is empty"
        exit 4
fi

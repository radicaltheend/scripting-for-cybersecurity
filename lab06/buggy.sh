#!/bin/bash

if [ ! -f "$1" ]; then
    echo "Error: file not found"
	exit 1
elif [ -f "$1" ]; then
	exit 0
fi




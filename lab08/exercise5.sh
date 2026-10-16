#!/bin/bash

FILE=""

[ -f $FILE ] && echo "unquoted: looks like a file"
[ -f "$FILE" ] && echo "quoted: looks like a file"

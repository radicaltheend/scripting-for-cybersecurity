#!/bin/bash

for FILE in case/evidence/* case/scripts/*; do
    TYPE=$(file -b "$FILE")
    if [[ "$FILE" == *.png ]]; then
        EXPECT="PNG"
    elif [[ "$FILE" == *.zip ]]; then
        EXPECT="Zip"
    elif [[ "$FILE" == *.txt || "$FILE" == *.md ]]; then
        EXPECT="text"
    elif [[ "$FILE" == *.bin ]]; then
	EXPECT="Bin"
    elif [[ "$FILE" == *.dat ]]; then
	EXPECT="Dat"
    elif [[ "$FILE" == *.sh ]]; then
        EXPECT="shell"
    elif [[ "$FILE" == *.py ]]; then
        EXPECT="Python"
    else
        EXPECT=""
    fi

    if [ -z "$FILE" ]; then
	echo "?? $FILE - empty file."
    elif [ -z "$EXPECT" ]; then
        echo "?? $FILE — no expectation for this extension; detected: $TYPE"
    elif [[ "$TYPE" == *"$EXPECT"* ]]; then
        echo "OK $FILE — $TYPE"
    else
        echo "!! $FILE — expected $EXPECT, detected: $TYPE"
    fi
done

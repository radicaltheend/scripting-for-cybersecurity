#!/bin/bash
for FILE in case/evidence/* case/scripts/* case/logs/*; do
    [ -f "$FILE" ] || continue
    echo "File name: $FILE"
    echo "File size: $(stat -c %s $FILE)"
    echo "File hash: $(sha256sum $FILE)"
    TYPE=$(file -b "$FILE")
    if [[ "$FILE" == *.png ]]; then
        EXPECT="PNG"
    elif [[ "$FILE" == *.zip ]]; then
        EXPECT="Zip"
    elif [[ "$FILE" == *.txt || "$FILE" == *.md ]]; then
        EXPECT="text"
	echo "Lines: $(wc -l $FILE | cut -d" " -f1)"
    elif [[ "$FILE" == *.bin ]]; then
	EXPECT="Bin"
    elif [[ "$FILE" == *.dat ]]; then
	EXPECT="Dat"
    elif [[ "$FILE" == *.sh ]]; then
        EXPECT="shell"
    elif [[ "$FILE" == *.py ]]; then
        EXPECT="Python"
    elif [[ "$FILE" == *.log ]]; then
	EXPECT="text"
	for INDICATOR in $(cat intel/iocs.txt); do
		if grep -qwF "$INDICATOR" "$FILE"; then
	 	echo "  MATCH: $INDICATOR ($(grep -cwF "$INDICATOR" "$FILE") lines)"
		fi
	done
    else
        EXPECT=""
    fi

    if [ -z "$FILE" ]; then
	echo "?? $FILE - empty file."
	echo ""
    elif [ -z "$EXPECT" ]; then
        echo "?? $FILE — no expectation for this extension; detected: $TYPE"
	echo ""
    elif [[ "$TYPE" == *"$EXPECT"* ]]; then
        echo "OK $FILE — $TYPE"
	echo ""
    else
        echo "!! $FILE — expected $EXPECT, detected: $TYPE"
	echo ""
    fi
done

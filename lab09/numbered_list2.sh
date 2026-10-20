#!/bin/bash

INDEX=1
for FILE in case/configs/*.conf case/*/*.log; do
    echo "File #$INDEX: $FILE"
    INDEX=$((INDEX + 1))
done

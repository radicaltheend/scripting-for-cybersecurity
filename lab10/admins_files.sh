#!/bin/bash

while IFS= read -r -d '' FILE; do
    echo "$FILE mentions admin ($(grep -c admin "$FILE") line(s))"
done < <(grep -rlZ "password" case)

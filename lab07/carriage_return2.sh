#!/bin/bash

expected="hello"
actual=$(printf 'hello\r')
actual=${actual%$'\r'}
if [[ "$actual" == "$expected" ]]; then
    echo "Match"
else
    echo "No match"
fi

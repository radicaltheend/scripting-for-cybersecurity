#!/bin/bash

expected="hello"
actual=$(printf 'hello\r')

if [[ "$actual" == "$expected" ]]; then
    echo "Match"
else
    echo "No match"
fi

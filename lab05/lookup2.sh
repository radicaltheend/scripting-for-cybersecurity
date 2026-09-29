#!/bin/bash

read -p "Enter a username and department to look up: " TARGET_USER TARGET_DEPT
echo "Searching the account and department list for: $TARGET_USER & $TARGET_DEPT"
grep "$TARGET_USER" intel/users.csv
grep "$TARGET_DEPT" intel/users.csv

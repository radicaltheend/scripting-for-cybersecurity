#!/bin/bash

read -p "Enter a username and department to look up: " TARGET_USER
echo "Searching the account and department list for: $TARGET_USER"
echo "The user role is: "
grep "$TARGET_USER" intel/users.csv | cut -d "," -f2
echo "The status of the account is: "
grep "$TARGET_USER" intel/users.csv | cut -d "," -f3

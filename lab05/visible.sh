#!/bin/bash
read -p "Enter a username: " USERNAME
echo ""
read -s -p "Enter the password: " PASSWORD
echo "username: $USERNAME"
echo "Length of password: ${#PASSWORD}"

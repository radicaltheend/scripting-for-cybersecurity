#!/bin/bash
username=$(whoami)
hostname=$(hostname)
direc=$(pwd)
linecount=$(ls -l | wc -l)

echo "user: $username"
echo "computer: $hostname"
echo "directory: $direc"
echo "items: $linecount"

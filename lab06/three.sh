#!/bin/bash

AUTH_LOG="case/logs/auth.log"

TOP_ATTACKERS=$(grep "Failed" "$AUTH_LOG" |
    awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' |
    sort | uniq -c | sort -nr | head -n 1)

echo "Top 1 failed-login sources:"
echo "$TOP_ATTACKERS"

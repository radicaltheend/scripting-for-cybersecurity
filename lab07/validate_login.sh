#!/bin/bash

LOG="case/logs/auth.log"
read -p "Enter the username: " username

if [ -z "$username" ]; then
echo "Username is empty"
exit 1
fi

if grep -q "^$username," intel/users.csv; then
    echo "$username: CURRENT account"
	type="current"
	exitcode=0
	status=$(grep "^$username," intel/users.csv | cut -d"," -f3)
	if [ "$status" = "disable" ]; then
	disabled=1
	fi
elif grep -qx "$username" case/backups/users.old; then
    echo "$username: LEGACY account (only in the old backup list)"
	type="legacy"
        exitcode=2
else
    echo "$username: UNKNOWN account (in neither list)"
	type="unknown"
	exitcode=3
fi

failed=$(grep -i "failed" "$LOG" | grep -c "$username")
accept=$(grep -i "accepted" "$LOG" | grep -c "$username")
echo "Failed password for $username: $failed"
echo "Accepted password for $username: $accept"

if [ "$failed" -eq 0 ]; then
    echo "Risk: NONE (no failed attempts)"
elif [ "$failed" -lt 5 ]; then
    echo "Risk: LOW ($failed failed attempts)"
elif [ "$failed" -lt 15 ]; then
    echo "Risk: MEDIUM ($failed failed attempts)"
else
    echo "Risk: HIGH ($failed failed attempts)"
fi

if [ "$type" = "current" ] && [ "$disabled" -eq 1 ] && [ "$accept" -gt 0 ]; then
    echo "WARNING: disabled current account '$username' has $accept accepted login(s)!"
fi

if [ "$type" != "current" ] && [ "$failed" -gt 0 ]; then
    echo "WARNING: $type account '$username' was targeted by $failed failed login(s) - attacker may be guessing account names!"
fi

if [ "$type" = "current" ] && [ "$accept" -gt 0 ] && grep -q "^$username:" case/evidence/passwords.txt; then
    echo "WARNING: current account '$username' has accepted logins AND appears in case/evidence/passwords.txt (plaintext credentials exposed)!"
fi
exit $exitcode

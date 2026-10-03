#!/bin/bash
BLOCK="$(grep -ci "block" case/logs/firewall.log)"
echo "There was $BLOCK block decisions on firewall"

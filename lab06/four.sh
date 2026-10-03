#!/bin/bash
echo "The amount of request for sqlmap was $(grep -c "sqlmap" case/logs/access.log) and it is $(($(grep -c "sqlmap" case/logs/access.log) * 100 / $(wc -l < case/logs/access.log)))% of the total"

#!/bin/bash
COUNT=$(grep -c "Failed password" case/logs/access.log || echo 0)
echo "[$COUNT]"

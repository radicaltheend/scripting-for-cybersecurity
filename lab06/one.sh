#!/bin/bash
WEB_LINES="case/logs/access.log"
echo "Number of lines: $(wc -l < $WEB_LINES)"

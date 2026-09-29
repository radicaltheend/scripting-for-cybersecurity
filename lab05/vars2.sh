#!/bin/bash

CASE_DIR="case2"
CASE_REF="CASE-2026-014"
LOG_DIR="$CASE_DIR/logs"
EVIDENCE_DIR="$CASE_DIR/evidence"
ANALYST="analyst"

echo "Analyst      : $ANALYST"
echo "Referential  : $CASE_REF" 
echo "Case folder  : $CASE_DIR"
echo "Log folder   : $LOG_DIR"
echo "Evidence     : $EVIDENCE_DIR"
echo ""
echo "Contents of $LOG_DIR:"
ls "$LOG_DIR"
echo ""
echo "Backup file for this case would be: ${CASE_DIR}_backup.tar"

#!/bin/bash
CASE_DIR="case"
read -p "Whats your name: " NAME
read -p "Case reference: " REFERENCE
echo "CREATING FILE WITH ADMIN ATTEMPTS..."
find "$CASE_DIR" -type f | xargs grep "admin" > REPORT.txt
echo "Your Name: $NAME"
echo "Reference Number: $REFERENCE"
echo ""
echo "Total Files: $(find $CASE_DIR -type f | wc -l)"
echo "Total directories: $(find $CASE_DIR -type d | wc -l)"
echo "Python Files: $(find $CASE_DIR -name "*.py" | wc -l)"
echo "Shell Scripts: $(find $CASE_DIR -name "*.sh" | wc -l)"
echo "Log Files: $(find $CASE_DIR -name "*.log" | wc -l)"
echo "Configuration Files: $(find $CASE_DIR -name "*.conf" | wc -l)"
echo "Empty Files: $(find $CASE_DIR -size 0 | wc -l)"
echo "Archives: $(find $CASE_DIR/evidence -type f | wc -l)"


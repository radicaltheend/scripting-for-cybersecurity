#!/bin/bash
./validate_file.sh ; echo "Exit code: $?" > result.txt
./validate_file.sh case/logs/missing.log ; echo "Exit code: $?" >> result.txt
./validate_file.sh case/evidence/empty.bin ; echo "Exit code: $?" >> result.txt
./validate_file.sh case/logs/auth.log ; echo "Exit code: $?" >> result.txt

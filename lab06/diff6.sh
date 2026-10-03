#!/bin/bash
./config_drift.sh case/config-old.txt case/config-new.txt && echo "Proceeding" || echo "Stopping"

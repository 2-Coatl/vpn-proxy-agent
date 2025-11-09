#!/bin/bash
# Watchdog for SSH Tunnel

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

source "${SCRIPT_DIR}/../utils/env.sh"

LOG_FILE="${LOGS_DIR}/watchdog.log"

while true; do
    if ! netstat -tlnp 2>/dev/null | grep -q ":1080"; then
        echo "[$(date)] Tunnel down, restarting..." >> "$LOG_FILE"
        ssh -D 1080 -f -N vpn-server 2>&1 | tee -a "$LOG_FILE"
    fi
    sleep 60
done

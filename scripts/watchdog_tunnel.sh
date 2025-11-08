#!/bin/bash
# Watchdog for SSH Tunnel
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${PROJECT_ROOT}/logs/watchdog.log"

while true; do
    if ! netstat -tlnp 2>/dev/null | grep -q ":1080"; then
        echo "[$(date)] Tunnel down, restarting..." >> "$LOG_FILE"
        ssh -D 1080 -f -N vpn-server 2>&1 | tee -a "$LOG_FILE"
    fi
    sleep 60
done

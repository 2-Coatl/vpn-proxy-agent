#!/bin/bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

source "${SCRIPT_DIR}/../utils/env.sh"

LOG_FILE="${LOGS_DIR}/restart_services.log"

echo "[$(date)] Restarting all services..." | tee -a "$LOG_FILE"
docker compose down 2>/dev/null || true
pkill -f "ssh.*-D.*1080" 2>/dev/null || true
sudo systemctl restart sshd
echo "[$(date)] Services restarted" | tee -a "$LOG_FILE"

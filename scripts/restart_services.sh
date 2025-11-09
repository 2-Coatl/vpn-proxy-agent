#!/bin/bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

source "${SCRIPT_DIR}/../utils/env.sh"
source "${SCRIPT_DIR}/../utils/logging.sh"

LOG_FILE="${LOGS_DIR}/restart_services.log"

log_file "$LOG_FILE" "Restarting services"

if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    log_file "$LOG_FILE" "Stopping Docker Compose services"
    docker compose down
else
    log_file "$LOG_FILE" "Docker Compose not available; skipping container shutdown"
fi

if pgrep -f "ssh.*-D.*1080" > /dev/null; then
    log_file "$LOG_FILE" "Stopping existing SSH tunnel processes"
    pkill -f "ssh.*-D.*1080"
else
    log_file "$LOG_FILE" "No SSH tunnel processes found"
fi

log_file "$LOG_FILE" "Restarting sshd"
sudo systemctl restart sshd

log_file "$LOG_FILE" "Service restart completed"

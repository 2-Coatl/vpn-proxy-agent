#!/bin/bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

source "${SCRIPT_DIR}/../utils/env.sh"

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUPS_DIR}/pre_update_${DATE}.tar.gz"
LOG_FILE="${LOGS_DIR}/update.log"

echo "[$(date)] Creating pre-update backup..." | tee -a "$LOG_FILE"
tar -czf "$BACKUP_FILE" "$PROJECT_ROOT" "$SCRIPTS_DIR" ~/.ssh 2>/dev/null || true
echo "[$(date)] Updating system..." | tee -a "$LOG_FILE"
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
echo "[$(date)] Update completed" | tee -a "$LOG_FILE"

#!/bin/bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

source "${SCRIPT_DIR}/../utils/env.sh"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/common.sh"

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUPS_DIR}/pre_update_${DATE}.tar.gz"
LOG_FILE="${LOGS_DIR}/update.log"

log_file "$LOG_FILE" "Creating pre-update backup"
create_tarball "$BACKUP_FILE" "Pre-update backup" "$PROJECT_ROOT" "$SCRIPTS_DIR" ~/.ssh

log_file "$LOG_FILE" "Updating system packages"
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

log_file "$LOG_FILE" "System update completed"

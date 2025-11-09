#!/bin/bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

source "${SCRIPT_DIR}/../utils/env.sh"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/common.sh"

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUPS_DIR"

create_tarball "$BACKUP_DIR/system_backup_${DATE}.tar.gz" "System backup" "$SCRIPTS_DIR" "$PROJECT_ROOT" ~/.ssh

mapfile -t old_backups < <(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -print)
if [ ${#old_backups[@]} -gt 0 ]; then
    rm -f "${old_backups[@]}"
    log_info "Removed old system backups"
fi

log_success "Backup completed: system_backup_${DATE}.tar.gz"

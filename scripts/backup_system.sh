#!/bin/bash
set -e

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

source "${SCRIPT_DIR}/../utils/env.sh"

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUPS_DIR"

tar -czf "$BACKUP_DIR/system_backup_${DATE}.tar.gz" "$SCRIPTS_DIR" "$PROJECT_ROOT" ~/.ssh 2>/dev/null
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
echo "Backup completed: system_backup_${DATE}.tar.gz"

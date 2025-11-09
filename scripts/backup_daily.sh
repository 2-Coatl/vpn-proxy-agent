#!/bin/bash
# Daily Backup Script
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

source "${SCRIPT_DIR}/../utils/env.sh"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/common.sh"

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUPS_DIR"
LOG_FILE="${LOGS_DIR}/backup.log"

log_file "$LOG_FILE" "Starting daily backup"

create_tarball "$BACKUP_DIR/ssh_config_$DATE.tar.gz" "SSH configuration backup" ~/.ssh /etc/ssh
create_tarball "$BACKUP_DIR/user_data_$DATE.tar.gz" "User workspace backup" ~/scripts ~/projects

if command -v docker &> /dev/null; then
    if docker ps >/dev/null 2>&1; then
        log_file "$LOG_FILE" "Backing up Docker containers"
        mapfile -t docker_containers < <(docker ps -a --format "{{.Names}}")
        for container in "${docker_containers[@]}"; do
            if [ -z "$container" ]; then
                continue
            fi
            backup_path="$BACKUP_DIR/docker_${container}_$DATE.tar"
            if docker export "$container" > "$backup_path"; then
                log_success "Exported container $container to $backup_path"
            else
                log_error "Failed to export container $container"
                exit 1
            fi
        done
    else
        log_file "$LOG_FILE" "Docker daemon unavailable; skipping container backups"
    fi
else
    log_file "$LOG_FILE" "Docker not available; skipping container backups"
fi

mapfile -t old_tar_gz < <(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -print)
if [ ${#old_tar_gz[@]} -gt 0 ]; then
    rm -f "${old_tar_gz[@]}"
    log_file "$LOG_FILE" "Removed old tar.gz backups"
fi

mapfile -t old_tar < <(find "$BACKUP_DIR" -name "*.tar" -mtime +7 -print)
if [ ${#old_tar[@]} -gt 0 ]; then
    rm -f "${old_tar[@]}"
    log_file "$LOG_FILE" "Removed old tar backups"
fi

log_file "$LOG_FILE" "Daily backup completed"

#!/bin/bash
# Daily Backup Script
set -e
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=~/backups
LOG_FILE=~/logs/backup.log

mkdir -p "$BACKUP_DIR" ~/logs

echo "[$(date)] Starting backup..." >> "$LOG_FILE"

# Backup SSH config
tar -czf "$BACKUP_DIR/ssh_config_$DATE.tar.gz" ~/.ssh/ /etc/ssh/ 2>/dev/null || true
echo "[$(date)] SSH config backed up" >> "$LOG_FILE"

# Backup scripts and projects
tar -czf "$BACKUP_DIR/user_data_$DATE.tar.gz" ~/scripts/ ~/projects/ 2>/dev/null || true
echo "[$(date)] User data backed up" >> "$LOG_FILE"

# Backup Docker volumes (if Docker installed)
if command -v docker &> /dev/null; then
    docker ps -a --format "{{.Names}}" | while read container; do
        docker export "$container" > "$BACKUP_DIR/docker_${container}_$DATE.tar" 2>/dev/null || true
    done
    echo "[$(date)] Docker containers backed up" >> "$LOG_FILE"
fi

# Clean old backups (keep 7 days)
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
find "$BACKUP_DIR" -name "*.tar" -mtime +7 -delete
echo "[$(date)] Old backups cleaned" >> "$LOG_FILE"

echo "[$(date)] Backup completed" >> "$LOG_FILE"

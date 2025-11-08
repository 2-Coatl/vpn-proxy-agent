#!/bin/bash
set -e
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=~/backups
mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/system_backup_$DATE.tar.gz ~/projects ~/scripts ~/.ssh 2>/dev/null
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
echo "Backup completed: system_backup_$DATE.tar.gz"

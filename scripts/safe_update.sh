#!/bin/bash
set -e
echo "Creating pre-update backup..."
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf ~/backups/pre_update_$DATE.tar.gz ~/{projects,scripts,.ssh} 2>/dev/null
echo "Updating system..."
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
echo "Update completed"

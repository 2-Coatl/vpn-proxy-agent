#!/bin/bash
set -e
echo "Restarting all services..."
docker compose down 2>/dev/null || true
pkill -f "ssh.*-D.*1080" 2>/dev/null || true
sudo systemctl restart sshd
echo "Services restarted"

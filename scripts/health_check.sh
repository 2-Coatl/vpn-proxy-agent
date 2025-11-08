#!/bin/bash
# Complete Health Check Script
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "${PROJECT_ROOT}/utils/logging.sh"

HEALTHY=true
REPORT=""

# Check SSH
if systemctl is-active --quiet sshd; then
    REPORT="${REPORT}\n[OK] SSH Server: Active"
else
    HEALTHY=false
    REPORT="${REPORT}\n[ERROR] SSH Server: Inactive"
fi

# Check Docker
if command -v docker &> /dev/null && docker ps &> /dev/null; then
    REPORT="${REPORT}\n[OK] Docker: Running"
else
    HEALTHY=false
    REPORT="${REPORT}\n[ERROR] Docker: Not running"
fi

# Check Tunnel
if netstat -tlnp 2>/dev/null | grep -q ":1080"; then
    REPORT="${REPORT}\n[OK] SOCKS5 Tunnel: Active"
else
    HEALTHY=false
    REPORT="${REPORT}\n[WARN] SOCKS5 Tunnel: Inactive"
fi

# Check APIs
for api in "https://api.anthropic.com" "https://api.openai.com"; do
    if timeout 5 curl -s -o /dev/null "$api"; then
        REPORT="${REPORT}\n[OK] $(basename $api): Reachable"
    else
        HEALTHY=false
        REPORT="${REPORT}\n[ERROR] $(basename $api): Unreachable"
    fi
done

# Check Disk Space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    HEALTHY=false
    REPORT="${REPORT}\n[ERROR] Disk usage critical: ${DISK_USAGE}%"
elif [ $DISK_USAGE -gt 80 ]; then
    REPORT="${REPORT}\n[WARN] Disk usage high: ${DISK_USAGE}%"
else
    REPORT="${REPORT}\n[OK] Disk usage: ${DISK_USAGE}%"
fi

# Output report
echo -e "Health Check Report - $(date)"
echo -e "$REPORT"
echo ""

if [ "$HEALTHY" = false ]; then
    echo "[STATUS] UNHEALTHY - Action required"
    exit 1
else
    echo "[STATUS] HEALTHY - All systems operational"
    exit 0
fi

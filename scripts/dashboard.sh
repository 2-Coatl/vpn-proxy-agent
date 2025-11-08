#!/bin/bash
# System Dashboard Script
set -e

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${REPO_ROOT}/utils/logging.sh"

clear
echo "=============================================="
echo "  SERVER STATUS DASHBOARD"
echo "=============================================="
echo ""

# Uptime
echo "System Uptime: $(uptime -p)"
echo ""

# Resources
echo "System Resources:"
echo "   CPU: $(top -bn1 | grep Cpu | awk '{print $2}') user"
echo "   RAM: $(free -h | awk 'NR==2{print $3"/"$2}')"
echo "   Disk: $(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')"
echo ""

# Docker
if command -v docker &> /dev/null; then
    echo "Docker Containers:"
    docker ps --format "   {{.Names}}: {{.Status}}" 2>/dev/null || echo "   Docker not running"
    echo ""
fi

# Network
echo "Network:"
echo "   SSH Connections: $(ss -tnp 2>/dev/null | grep :22 | wc -l)"
if netstat -tlnp 2>/dev/null | grep -q ":1080"; then
    echo "   [OK] SOCKS5 Tunnel Active"
else
    echo "   [WARN] SOCKS5 Tunnel Inactive"
fi
echo ""

echo "Last updated: $(date)"
echo "=============================================="

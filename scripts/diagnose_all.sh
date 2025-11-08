#!/bin/bash
# =============================================================================
# VPN/Proxy Agent - Complete System Diagnostic
# =============================================================================
# Description: Comprehensive system health check
# Usage: ./scripts/diagnose_all.sh
# =============================================================================

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${REPO_ROOT}/utils/logging.sh"
source "${REPO_ROOT}/utils/validation.sh"
source "${REPO_ROOT}/utils/common.sh"

# -----------------------------------------------------------------------------
# Main Function
# -----------------------------------------------------------------------------

main() {
    echo "=============================================="
    echo "  COMPLETE SYSTEM DIAGNOSTIC"
    echo "=============================================="
    echo ""
    
    # OS Information
    echo "[System] Operating System:"
    detect_os_version
    echo "   OS: $OS_PRETTY_NAME"
    echo "   Kernel: $(uname -r)"
    echo "   Uptime: $(uptime -p)"
    echo ""
    
    # Resources
    echo "[System] Resources:"
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    local ram_used=$(free -m | awk 'NR==2{print $3}')
    local ram_total=$(free -m | awk 'NR==2{print $2}')
    local ram_percent=$(awk "BEGIN {printf \"%.1f\", ($ram_used/$ram_total)*100}")
    local disk_info=$(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')
    
    echo "   CPU Usage: ${cpu_usage}%"
    echo "   RAM: ${ram_used}MB / ${ram_total}MB (${ram_percent}%)"
    echo "   Disk /: $disk_info"
    
    if [ -d "/srv/data" ]; then
        local data_disk=$(df -h /srv/data | awk 'NR==2{print $3"/"$2" ("$5")"}')
        echo "   Disk /srv/data: $data_disk"
    fi
    echo ""
    
    # SSH Service
    echo "[Services] SSH Server:"
    if systemctl is-active --quiet sshd; then
        echo "   [OK] SSH Server: Active"
        local ssh_conns=$(ss -tnp 2>/dev/null | grep :22 | wc -l)
        echo "   Connections: $ssh_conns"
    else
        echo "   [ERROR] SSH Server: Inactive"
    fi
    echo ""
    
    # Firewall
    echo "[Security] Firewall (UFW):"
    if command -v ufw &> /dev/null; then
        sudo ufw status | head -5
    else
        echo "   [WARN] UFW not installed"
    fi
    echo ""
    
    # Docker
    echo "[Services] Docker:"
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | cut -d' ' -f3 | tr -d ',')
        echo "   [OK] Docker: $docker_version"
        
        local containers_running=$(docker ps -q | wc -l)
        local containers_total=$(docker ps -aq | wc -l)
        local images_count=$(docker images -q | wc -l)
        local volumes_count=$(docker volume ls -q | wc -l)
        
        echo "   Containers: $containers_running running / $containers_total total"
        echo "   Images: $images_count"
        echo "   Volumes: $volumes_count"
        
        if [ $containers_running -gt 0 ]; then
            echo ""
            echo "   Running Containers:"
            docker ps --format "      - {{.Names}}: {{.Status}}"
        fi
    else
        echo "   [WARN] Docker not installed"
    fi
    echo ""
    
    # VPN/Tunnels
    echo "[Network] VPN/Tunnels:"
    if netstat -tlnp 2>/dev/null | grep -q ":1080"; then
        echo "   [OK] SOCKS5 Tunnel (1080): Active"
    else
        echo "   [WARN] SOCKS5 Tunnel (1080): Inactive"
    fi
    
    if command -v wg &> /dev/null && [ -d "/etc/wireguard" ]; then
        if ip link show wg0 &> /dev/null 2>&1; then
            echo "   [OK] WireGuard (wg0): Active"
            local wg_peers=$(sudo wg show wg0 peers 2>/dev/null | wc -l)
            echo "      Peers: $wg_peers"
        else
            echo "   [WARN] WireGuard: Configured but inactive"
        fi
    fi
    echo ""
    
    # API Connectivity
    echo "[Network] API Connectivity Test:"
    local apis=(
        "https://api.anthropic.com"
        "https://api.openai.com"
        "https://copilot-proxy.githubusercontent.com"
    )
    
    for api in "${apis[@]}"; do
        local api_name=$(basename $api | cut -d. -f1)
        echo -n "   Testing $api_name: "
        
        if timeout 5 curl -s -o /dev/null -w "%{http_code}" "$api" | grep -q "200\|405"; then
            echo "[OK]"
        else
            echo "[FAIL]"
        fi
    done
    echo ""
    
    # System Updates
    echo "[System] Available Updates:"
    if command -v apt &> /dev/null; then
        local updates=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
        if [ $updates -gt 0 ]; then
            echo "   [WARN] $updates packages can be updated"
        else
            echo "   [OK] System is up to date"
        fi
    fi
    echo ""
    
    # Recent SSH Logins
    echo "[Security] Recent SSH Logins:"
    last -n 3 | head -3 | awk '{print "   " $0}'
    echo ""
    
    # Backups
    if [ -d ~/backups ]; then
        local backup_count=$(ls ~/backups/*.tar.gz 2>/dev/null | wc -l)
        if [ $backup_count -gt 0 ]; then
            echo "[Maintenance] Backups:"
            local latest_backup=$(ls -t ~/backups/*.tar.gz 2>/dev/null | head -1)
            echo "   Count: $backup_count"
            echo "   Latest: $(basename $latest_backup)"
            echo "   Size: $(du -h $latest_backup 2>/dev/null | cut -f1)"
        fi
    fi
    
    echo ""
    echo "=============================================="
    echo "Diagnostic completed: $(date)"
    echo "=============================================="
}

# Run main
main "$@"

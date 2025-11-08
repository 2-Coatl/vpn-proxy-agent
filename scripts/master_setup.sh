#!/bin/bash
# =============================================================================
# VPN/Proxy Agent - Master Setup Script
# =============================================================================
# Description: Complete system setup including all components
# Usage: ./scripts/master_setup.sh
# =============================================================================

set -e

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/validation.sh"
source "${PROJECT_ROOT}/utils/common.sh"

# Load configuration
CONFIG_FILE="${PROJECT_ROOT}/config/versions.conf"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# -----------------------------------------------------------------------------
# Main Setup Function
# -----------------------------------------------------------------------------

main() {
    log_header "MASTER SETUP - COMPLETE SYSTEM INSTALLATION"
    
    start_timer "master_setup"
    
    # Step 1: Update system
    log_step 1 10 "Updating system packages"
    update_package_lists || {
        log_error "Failed to update package lists"
        return 1
    }
    sudo apt upgrade -y
    
    # Step 2: Install Docker
    log_step 2 10 "Installing Docker"
    if ! command -v docker &>/dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        sudo usermod -aG docker "$USER"
    else
        log_info "Docker already installed"
    fi
    
    # Step 3: Install Docker Compose
    log_step 3 10 "Installing Docker Compose"
    if ! docker compose version &> /dev/null; then
        sudo apt install -y docker-compose-plugin
    else
        log_info "Docker Compose already installed"
    fi
    
    # Step 4: Configure Firewall
    log_step 4 10 "Configuring UFW"
    if ! is_package_installed ufw; then
        install_packages ufw
    fi
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp
    sudo ufw allow 53/tcp
    echo "y" | sudo ufw enable || log_warn "UFW already enabled"
    
    # Step 5: Install Fail2Ban
    log_step 5 10 "Installing Fail2Ban"
    if ! is_package_installed fail2ban; then
        install_packages fail2ban
        enable_service fail2ban
    else
        log_info "Fail2Ban already installed"
    fi
    
    # Step 6: Create directory structure
    log_step 6 10 "Creating directory structure"
    mkdir -p ~/projects ~/scripts ~/logs ~/backups
    sudo mkdir -p /srv/data/{postgres,redis,uploads,backups}
    sudo chown -R "$USER:$USER" /srv/data
    
    # Step 7: Configure backups
    log_step 7 10 "Configuring automated backups"
    cat > ~/scripts/backup_daily.sh << 'EOFBACKUP'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf ~/backups/backup_$DATE.tar.gz ~/projects ~/scripts 2>/dev/null
find ~/backups -name "*.tar.gz" -mtime +7 -delete
echo "[$(date)] Backup completed: backup_$DATE.tar.gz" >> ~/logs/backup.log
EOFBACKUP
    chmod +x ~/scripts/backup_daily.sh
    
    # Step 8: Configure cron jobs
    log_step 8 10 "Configuring cron jobs"
    (crontab -l 2>/dev/null | grep -v "backup_daily.sh"; echo "0 3 * * * ~/scripts/backup_daily.sh") | crontab -
    
    # Step 9: Install monitoring tools
    log_step 9 10 "Installing monitoring tools"
    install_packages htop iotop nethogs ncdu
    
    # Step 10: Install Netdata (optional)
    log_step 10 10 "Installing Netdata"
    if log_confirm "Install Netdata monitoring? (recommended)" "y"; then
        bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait --disable-telemetry || {
            log_warn "Netdata installation failed (non-critical)"
        }
    fi
    
    end_timer "master_setup" "Master setup"
    
    log_header "SETUP COMPLETED"
    
    log_summary_start
    log_summary_item "Status" "SUCCESS"
    log_summary_item "Docker" "$(docker --version 2>/dev/null || echo 'Installed')"
    log_summary_item "UFW" "$(sudo ufw status | head -1)"
    log_summary_item "Fail2Ban" "$(systemctl is-active fail2ban)"
    log_summary_end
    
    echo ""
    echo "NEXT STEPS:"
    echo "1. Log out and back in (for docker group)"
    echo "2. Configure SSH keys: ./scripts/setup_ssh.sh"
    echo "3. Setup tunnel: ./scripts/setup_tunnel.sh"
    echo ""
    
    return 0
}

# Run main
main "$@"

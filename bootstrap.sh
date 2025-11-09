#!/bin/bash
# =============================================================================
# VPN/Proxy Agent - Bootstrap Script
# =============================================================================
# Description: Main installation orchestrator
# Usage: ./bootstrap.sh [--quick|--standard|--complete]
# =============================================================================

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

if [[ -f "${SCRIPT_DIR}/utils/env.sh" ]]; then
    source "${SCRIPT_DIR}/utils/env.sh"
else
    echo "Error: No se encontró ${SCRIPT_DIR}/utils/env.sh" >&2
    exit 1
fi

REPO_ROOT="$SCRIPT_DIR"
UTILS_DIR="${REPO_ROOT}/utils"
REQUIRED_UTILS=("logging.sh" "validation.sh" "common.sh")

for file in "${REQUIRED_UTILS[@]}"; do
    FULL_PATH="${UTILS_DIR}/${file}"
    if [[ -f "$FULL_PATH" ]]; then
        source "$FULL_PATH"
    else
        echo "Advertencia: No se encontró $FULL_PATH"
    fi
done

# -----------------------------------------------------------------------------
# Constantes
# -----------------------------------------------------------------------------
VERSION="1.0.0"
LOG_FILE="${LOGS_DIR}/bootstrap_$(date +%Y%m%d_%H%M%S).log"
echo "Versión: $VERSION"
echo "Archivo de log: $LOG_FILE"

# Installation types
INSTALL_QUICK="quick"
INSTALL_STANDARD="standard"
INSTALL_COMPLETE="complete"

# Default selections for automation
DEFAULT_AUTO_INSTALL="$INSTALL_STANDARD"

# -----------------------------------------------------------------------------
# Automation Helpers
# -----------------------------------------------------------------------------

# Determine if bootstrap should run without interactive prompts
auto_mode_enabled() {
    local flag

    flag="${BOOTSTRAP_AUTO:-}"
    if [[ -n "$flag" ]]; then
        flag="${flag,,}"
        if [[ "$flag" =~ ^(1|true|yes|y)$ ]]; then
            return 0
        fi
    fi

    flag="${CI:-}"
    if [[ -n "$flag" ]]; then
        flag="${flag,,}"
        if [[ "$flag" =~ ^(1|true|yes|y)$ ]]; then
            return 0
        fi
    fi

    if [ ! -t 0 ]; then
        return 0
    fi

    return 1
}

# Check whether we should auto-confirm prompts
should_auto_confirm() {
    if auto_mode_enabled; then
        return 0
    fi

    local flag="${BOOTSTRAP_ASSUME_YES:-}"
    if [[ -n "$flag" ]]; then
        flag="${flag,,}"
        if [[ "$flag" =~ ^(1|true|yes|y)$ ]]; then
            return 0
        fi
    fi

    return 1
}

# Validate provided install type
is_valid_install_type() {
    local candidate="$1"

    case "$candidate" in
        "$INSTALL_QUICK"|"$INSTALL_STANDARD"|"$INSTALL_COMPLETE")
            return 0
            ;;
    esac

    return 1
}

# Resolve the installation type respecting automation flags
resolve_install_type() {
    local cli_choice="${1-}"

    if [ -n "$cli_choice" ]; then
        echo "$cli_choice"
        return 0
    fi

    local env_choice="${BOOTSTRAP_INSTALL_TYPE:-}"

    if auto_mode_enabled; then
        local candidate="$DEFAULT_AUTO_INSTALL"

        if [ -n "$env_choice" ]; then
            candidate="$env_choice"
        fi

        if ! is_valid_install_type "$candidate"; then
            log_warn "Invalid install type '$candidate' provided for automation. Falling back to '$DEFAULT_AUTO_INSTALL'."
            candidate="$DEFAULT_AUTO_INSTALL"
        fi

        echo "$candidate"
        return 0
    fi

    if [ -n "$env_choice" ]; then
        if is_valid_install_type "$env_choice"; then
            echo "$env_choice"
            return 0
        fi
        log_warn "Ignoring invalid BOOTSTRAP_INSTALL_TYPE='$env_choice'"
    fi

    select_install_type
}

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

# Show usage
show_usage() {
    cat << EOF
VPN/Proxy Agent Bootstrap Script v${VERSION}

USAGE:
    ./bootstrap.sh [OPTIONS]

OPTIONS:
    --quick         Quick install (SSH Tunnel only - 45 min)
    --standard      Standard install (SSH + Docker + Security - 4 hours)
    --complete      Complete install (Everything + WireGuard - 9 hours)
    --help          Show this help message

INSTALLATION TYPES:

    QUICK (45 minutes)
    - SSH key setup
    - SSH SOCKS5 tunnel
    - Basic security (UFW)
    - Minimal configuration

    STANDARD (4 hours)
    - Everything in Quick
    - Docker + Docker Compose
    - VS Code Remote SSH
    - Fail2Ban
    - Monitoring (basic)
    - Automated backups

    COMPLETE (9 hours)
    - Everything in Standard
    - WireGuard VPN
    - Advanced security hardening
    - Full monitoring (Netdata)
    - Optimizations
    - All optional features

EXAMPLES:
    ./bootstrap.sh                    # Interactive mode
    ./bootstrap.sh --quick            # Quick installation
    ./bootstrap.sh --standard         # Standard installation
    ./bootstrap.sh --complete         # Complete installation

EOF
}

# Show welcome banner
show_welcome() {
    log_box "VPN/Proxy Agent v${VERSION}"
    echo ""
    log_info "Complete automation for VPN/Proxy setup"
    log_info "with VS Code Remote SSH and Docker integration"
    echo ""
}

# Check system requirements
check_requirements() {
    log_header "Checking System Requirements"
    
    start_timer "requirements"
    
    # Check OS
    log_step 1 "Validating Ubuntu version"
    if ! validate_ubuntu_version; then
        log_error "This installer requires Ubuntu 20.04, 22.04, or 24.04"
        return 1
    fi
    
    # Check not running as root
    log_step 2 "Checking user privileges"
    if [ "$EUID" -eq 0 ]; then
        log_error "Do not run this script as root. Run as regular user with sudo privileges."
        return 1
    fi
    
    # Check sudo access
    log_step 3 "Validating sudo access"
    if ! sudo -n true 2>/dev/null; then
        log_info "Sudo access required. You may be prompted for password."
        sudo -v || {
            log_error "Sudo access is required for installation"
            return 1
        }
    fi
    
    # Check disk space
    log_step 4 "Checking disk space"
    if ! validate_disk_space "/" 5000; then
        log_error "Insufficient disk space (need at least 5GB free)"
        return 1
    fi
    
    # Check RAM
    log_step 5 "Checking available RAM"
    if ! validate_ram 1024; then
        log_warn "Low RAM detected (less than 1GB). Installation may be slow."
    fi
    
    # Check required commands
    log_step 6 "Validating required commands"
    local required_commands=("curl" "wget" "tar" "grep" "sed" "awk")
    if ! validate_commands_exist "${required_commands[@]}"; then
        log_error "Missing required commands. Installing..."
        install_packages curl wget tar grep sed gawk || return 1
    fi
    
    end_timer "requirements" "Requirements check"
    
    log_success "All system requirements met"
    echo ""
    return 0
}

# Select installation type
select_install_type() {
    local install_type="${1-}"
    
    if [ -n "$install_type" ]; then
        echo "$install_type"
        return 0
    fi
    
    log_header "Select Installation Type"
    
    echo "Choose installation type:"
    echo ""
    echo "  1) Quick       - SSH Tunnel only (45 min)"
    echo "  2) Standard    - SSH + Docker + Security (4 hours)"
    echo "  3) Complete    - Everything + WireGuard (9 hours)"
    echo ""
    echo -n "Enter choice [1-3]: "
    read -r choice
    
    case "$choice" in
        1) echo "$INSTALL_QUICK" ;;
        2) echo "$INSTALL_STANDARD" ;;
        3) echo "$INSTALL_COMPLETE" ;;
        *)
            log_error "Invalid choice"
            return 1
            ;;
    esac
}

# Show installation summary
show_install_summary() {
    local install_type="$1"
    
    log_summary_start
    log_summary_item "Installation Type" "$(to_uppercase $install_type)"
    log_summary_item "OS Version" "$OS_PRETTY_NAME"
    log_summary_item "User" "$USER"
    log_summary_item "Working Directory" "$SCRIPT_DIR"
    log_summary_item "Log File" "$LOG_FILE"
    
    case "$install_type" in
        "$INSTALL_QUICK")
            log_summary_item "Estimated Time" "45 minutes"
            log_summary_item "Components" "SSH Tunnel, Basic Security"
            ;;
        "$INSTALL_STANDARD")
            log_summary_item "Estimated Time" "4 hours"
            log_summary_item "Components" "SSH, Docker, VS Code, Security, Monitoring"
            ;;
        "$INSTALL_COMPLETE")
            log_summary_item "Estimated Time" "9 hours"
            log_summary_item "Components" "All features including WireGuard VPN"
            ;;
    esac
    
    log_summary_end
}

# Prepare environment
prepare_environment() {
    log_header "Preparing Environment"
    
    start_timer "prepare"
    
    # Create directories
    log_step 1 "Creating directory structure"
    create_directory "$LOGS_DIR" || return 1
    create_directory "$BACKUPS_DIR" || return 1
    create_directory "$SCRIPTS_DIR" || return 1
    
    # Update package lists
    log_step 2 "Updating package lists"
    update_package_lists || return 1
    
    # Install basic dependencies
    log_step 3 "Installing basic dependencies"
    local packages=(
        "build-essential"
        "curl"
        "wget"
        "git"
        "vim"
        "nano"
        "htop"
        "net-tools"
        "ca-certificates"
        "gnupg"
        "lsb-release"
    )
    install_packages "${packages[@]}" || return 1
    
    end_timer "prepare" "Environment preparation"
    
    log_success "Environment prepared"
    echo ""
    return 0
}

# Install SSH components
install_ssh() {
    log_header "Installing SSH Components"
    
    start_timer "ssh"
    
    # Install OpenSSH server
    log_step 1 "Installing OpenSSH server"
    install_packages openssh-server || return 1
    
    # Configure SSH
    log_step 2 "Configuring SSH"
    if [ ! -f "${SCRIPTS_DIR}/setup_ssh.sh" ]; then
        log_error "Required script not found: ${SCRIPTS_DIR}/setup_ssh.sh"
        return 1
    fi

    log_info "Executing SSH setup helper"
    if ! bash "${SCRIPTS_DIR}/setup_ssh.sh"; then
        log_error "SSH configuration script failed"
        return 1
    fi
    
    # Enable SSH service
    log_step 3 "Enabling SSH service"
    enable_service ssh || return 1
    
    end_timer "ssh" "SSH installation"
    
    log_success "SSH components installed"
    echo ""
    return 0
}

# Install Docker
install_docker() {
    log_header "Installing Docker"
    
    start_timer "docker"
    
    # Check if already installed
    if command -v docker &>/dev/null; then
        log_info "Docker already installed"
        docker --version
        return 0
    fi
    
    # Install Docker
    log_step 1 "Installing Docker Engine"
    log_info "Downloading Docker install script..."
    
    local temp_dir=$(create_temp_dir)
    register_cleanup_trap "$temp_dir"
    
    download_file "$DOCKER_INSTALL_URL" "${temp_dir}/get-docker.sh" "Docker installer" || return 1
    
    log_info "Running Docker installer..."
    sudo sh "${temp_dir}/get-docker.sh" || {
        log_error "Docker installation failed"
        return 1
    }
    
    # Add user to docker group
    log_step 2 "Adding user to docker group"
    sudo usermod -aG docker "$USER" || log_warn "Failed to add user to docker group"
    
    # Install Docker Compose plugin
    log_step 3 "Installing Docker Compose"
    install_packages docker-compose-plugin || return 1
    
    # Enable Docker service
    log_step 4 "Enabling Docker service"
    enable_service docker || return 1
    
    end_timer "docker" "Docker installation"
    
    log_success "Docker installed successfully"
    log_info "You may need to log out and back in for docker group changes to take effect"
    echo ""
    return 0
}

# Install security components
install_security() {
    log_header "Installing Security Components"
    
    start_timer "security"
    
    # Install UFW
    log_step 1 "Installing UFW firewall"
    install_packages ufw || return 1
    
    # Configure UFW
    log_step 2 "Configuring UFW"
    sudo ufw default deny incoming || return 1
    sudo ufw default allow outgoing || return 1
    sudo ufw allow ssh || return 1
    
    log_info "Enabling UFW..."
    echo "y" | sudo ufw enable || log_warn "Failed to enable UFW"
    
    # Install Fail2Ban
    log_step 3 "Installing Fail2Ban"
    install_packages fail2ban || return 1
    enable_service fail2ban || log_warn "Failed to enable Fail2Ban"
    
    end_timer "security" "Security installation"
    
    log_success "Security components installed"
    echo ""
    return 0
}

# Install monitoring
install_monitoring() {
    log_header "Installing Monitoring Components"

    start_timer "monitoring"

    # Install basic monitoring tools
    log_step 1 "Installing monitoring tools"
    install_packages htop iotop nethogs ncdu || return 1
    
    # Install Netdata (optional)
    if log_confirm "Install Netdata (web-based monitoring)?"; then
        log_step 2 "Installing Netdata"
        log_info "This may take several minutes..."
        
        bash <(curl -Ss "$NETDATA_INSTALL_URL") --dont-wait --disable-telemetry || {
            log_warn "Netdata installation failed (non-critical)"
        }
    fi
    
    end_timer "monitoring" "Monitoring installation"
    
    log_success "Monitoring components installed"
    echo ""
    return 0
}

# Install WireGuard VPN
install_wireguard() {
    log_header "Installing WireGuard VPN"

    start_timer "wireguard"

    if [ ! -f "${SCRIPTS_DIR}/setup_wireguard.sh" ]; then
        log_error "Required script not found: ${SCRIPTS_DIR}/setup_wireguard.sh"
        return 1
    fi

    log_step 1 "Executing WireGuard setup script"
    if ! bash "${SCRIPTS_DIR}/setup_wireguard.sh"; then
        log_error "WireGuard setup script failed"
        return 1
    fi

    end_timer "wireguard" "WireGuard installation"

    log_success "WireGuard installed"
    echo ""
    return 0
}

# Setup backups
setup_backups() {
    log_header "Setting Up Automated Backups"
    
    start_timer "backups"
    
    local cron_file="/etc/cron.d/vpn_proxy_backups"
    local cron_user
    cron_user=$(whoami)

    log_step 1 "Validating backup scripts"
    for script in "${SCRIPTS_DIR}/backup_daily.sh" "${SCRIPTS_DIR}/backup_system.sh"; do
        if [ ! -f "$script" ]; then
            log_error "Missing backup script: $script"
            return 1
        fi
        chmod +x "$script" || {
            log_error "Failed to mark $script as executable"
            return 1
        }
    done

    log_step 2 "Ensuring backup directories exist"
    create_directory "$BACKUPS_DIR" 750 "$cron_user" || return 1
    create_directory "$LOGS_DIR" 750 "$cron_user" || return 1

    log_step 3 "Registering cron jobs"
    sudo tee "$cron_file" >/dev/null <<EOCRON
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

0 2 * * * ${cron_user} cd "${PROJECT_ROOT}" && bash "${SCRIPTS_DIR}/backup_daily.sh" >> "${LOGS_DIR}/backup_cron.log" 2>&1
30 2 * * 0 ${cron_user} cd "${PROJECT_ROOT}" && bash "${SCRIPTS_DIR}/backup_system.sh" >> "${LOGS_DIR}/backup_cron.log" 2>&1
EOCRON

    sudo chmod 644 "$cron_file" || log_warn "Failed to set permissions on $cron_file"

    log_info "Backup cron configuration written to $cron_file"
    
    end_timer "backups" "Backup setup"
    
    log_success "Backup system configured"
    echo ""
    return 0
}

# Perform quick installation
do_quick_install() {
    log_info "Starting Quick Installation..."
    echo ""
    
    prepare_environment || return 1
    install_ssh || return 1
    install_security || return 1
    
    return 0
}

# Perform standard installation
do_standard_install() {
    log_info "Starting Standard Installation..."
    echo ""
    
    prepare_environment || return 1
    install_ssh || return 1
    install_docker || return 1
    install_security || return 1
    install_monitoring || return 1
    setup_backups || return 1
    
    return 0
}

# Perform complete installation
do_complete_install() {
    log_info "Starting Complete Installation..."
    echo ""
    
    prepare_environment || return 1
    install_ssh || return 1
    install_docker || return 1
    install_security || return 1
    install_monitoring || return 1
    setup_backups || return 1
    install_wireguard || return 1

    return 0
}

# Show completion message
show_completion() {
    local install_type="$1"
    local total_time="$2"
    
    log_box "Installation Complete!"
    
    echo ""
    log_success "VPN/Proxy Agent has been successfully installed"
    echo ""
    
    log_summary_start
    log_summary_item "Installation Type" "$(to_uppercase $install_type)"
    log_summary_item "Total Time" "$total_time"
    log_summary_item "Log File" "$LOG_FILE"
    log_summary_end
    
    echo "NEXT STEPS:"
    echo ""
    echo "1. Review installation log: cat $LOG_FILE"
    echo "2. Log out and back in (for group changes)"
    echo "3. Configure SSH keys (if not done)"
    echo "4. Start SSH tunnel or WireGuard VPN"
    echo "5. Test connectivity to blocked APIs"
    echo ""
    echo "For detailed instructions, see:"
    echo "  - README.md"
    echo "  - Documentation in docs/"
    echo ""
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    local install_type=""
    
    # Parse arguments
    case "${1:-}" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --quick)
            install_type="$INSTALL_QUICK"
            ;;
        --standard)
            install_type="$INSTALL_STANDARD"
            ;;
        --complete)
            install_type="$INSTALL_COMPLETE"
            ;;
        "")
            # Interactive mode
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    
    # Start logging
    mkdir -p "$(dirname "$LOG_FILE")"
    exec > >(tee -a "$LOG_FILE")
    exec 2>&1
    
    # Start timer
    start_timer "total"
    
    # Show welcome
    show_welcome
    
    # Check requirements
    if ! check_requirements; then
        log_error "System requirements not met"
        exit 1
    fi
    
    # Detect OS
    detect_os_version
    
    install_type=$(resolve_install_type "$install_type") || {
        log_error "Installation cancelled"
        exit 1
    }

    if auto_mode_enabled; then
        log_info "Automation mode detected. Selected installation type: $install_type"
    fi

    # Show summary
    show_install_summary "$install_type"

    # Confirm installation
    echo ""
    if should_auto_confirm; then
        log_info "Auto-confirmation enabled. Proceeding without prompt."
    else
        if ! log_confirm "Proceed with installation?" "y"; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi
    echo ""
    
    # Perform installation
    case "$install_type" in
        "$INSTALL_QUICK")
            do_quick_install || exit 1
            ;;
        "$INSTALL_STANDARD")
            do_standard_install || exit 1
            ;;
        "$INSTALL_COMPLETE")
            do_complete_install || exit 1
            ;;
    esac
    
    # Show completion
    local total_time=$(end_timer "total" "Total installation")
    show_completion "$install_type" "$total_time"
    
    exit 0
}

# Run main when executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

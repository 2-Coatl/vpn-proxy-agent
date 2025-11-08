#!/bin/bash
# =============================================================================
# VPN/Proxy Agent - Standalone Installer
# =============================================================================
# Description: Standalone installer that can be run independently
# Usage: curl -sSL https://raw.githubusercontent.com/org/repo/main/installer/install.sh | bash
# =============================================================================

set -e

# Configuration
VERSION="1.0.0"
PROJECT_NAME="vpn-proxy-agent"
INSTALL_DIR="$HOME/$PROJECT_NAME"
REPO_URL="https://github.com/your-org/vpn-proxy-agent"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

check_requirements() {
    log_info "Checking system requirements..."
    
    # Check OS
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot determine OS"
        return 1
    fi
    
    source /etc/os-release
    if [ "$ID" != "ubuntu" ] && [ "$ID" != "debian" ]; then
        log_error "This installer requires Ubuntu or Debian"
        return 1
    fi
    
    # Check not root
    if [ "$EUID" -eq 0 ]; then
        log_error "Do not run as root. Run as regular user with sudo privileges"
        return 1
    fi
    
    # Check sudo
    if ! sudo -n true 2>/dev/null; then
        log_info "Sudo access required. You may be prompted for password."
        sudo -v || {
            log_error "Sudo access is required"
            return 1
        }
    fi
    
    # Check disk space (need at least 1GB)
    local available_kb=$(df "$HOME" | awk 'NR==2 {print $4}')
    local available_mb=$((available_kb / 1024))
    if [ "$available_mb" -lt 1000 ]; then
        log_error "Insufficient disk space (need at least 1GB)"
        return 1
    fi
    
    # Check required commands
    for cmd in curl wget tar git; do
        if ! command -v $cmd &>/dev/null; then
            log_error "Required command not found: $cmd"
            return 1
        fi
    done
    
    log_success "System requirements met"
    return 0
}

download_project() {
    log_info "Downloading $PROJECT_NAME..."
    
    if [ -d "$INSTALL_DIR" ]; then
        log_warn "Installation directory already exists: $INSTALL_DIR"
        if [ "$(ls -A $INSTALL_DIR)" ]; then
            log_error "Directory is not empty. Please remove or backup first"
            return 1
        fi
    fi
    
    # Try git clone first
    if command -v git &>/dev/null; then
        git clone "$REPO_URL" "$INSTALL_DIR" || {
            log_error "Failed to clone repository"
            return 1
        }
    else
        # Fallback to downloading tarball
        log_warn "Git not available, downloading tarball..."
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        wget -O project.tar.gz "${REPO_URL}/archive/refs/heads/main.tar.gz" || {
            log_error "Failed to download project"
            rm -rf "$temp_dir"
            return 1
        }
        
        tar -xzf project.tar.gz
        mv ${PROJECT_NAME}-main "$INSTALL_DIR"
        cd -
        rm -rf "$temp_dir"
    fi
    
    log_success "Project downloaded to $INSTALL_DIR"
    return 0
}

install_project() {
    log_info "Installing $PROJECT_NAME..."
    
    cd "$INSTALL_DIR"
    
    # Make scripts executable
    chmod +x bootstrap.sh
    chmod +x utils/*.sh
    chmod +x scripts/*.sh 2>/dev/null || true
    chmod +x tests/*.sh 2>/dev/null || true
    
    log_success "Project installed successfully"
    return 0
}

show_next_steps() {
    echo ""
    echo "=============================================="
    echo "  Installation Complete!"
    echo "=============================================="
    echo ""
    echo "Next steps:"
    echo "  1. cd $INSTALL_DIR"
    echo "  2. ./bootstrap.sh"
    echo ""
    echo "For quick setup:"
    echo "  cd $INSTALL_DIR && ./bootstrap.sh --quick"
    echo ""
    echo "For help:"
    echo "  ./bootstrap.sh --help"
    echo ""
}

# -----------------------------------------------------------------------------
# Main Installation
# -----------------------------------------------------------------------------

main() {
    echo "=============================================="
    echo "  $PROJECT_NAME Installer v$VERSION"
    echo "=============================================="
    echo ""
    
    # Check requirements
    if ! check_requirements; then
        log_error "System requirements not met"
        exit 1
    fi
    
    # Download project
    if ! download_project; then
        log_error "Failed to download project"
        exit 1
    fi
    
    # Install project
    if ! install_project; then
        log_error "Failed to install project"
        exit 1
    fi
    
    # Show next steps
    show_next_steps
    
    exit 0
}

# Run main
main "$@"

#!/bin/bash
# =============================================================================
# VPN/Proxy Agent - Common Utilities
# =============================================================================
# Description: Common helper functions used across scripts
# Usage: source utils/common.sh
# =============================================================================

# -----------------------------------------------------------------------------
# Determinar la ruta absoluta del directorio de este script
# -----------------------------------------------------------------------------
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# -----------------------------------------------------------------------------
# Cargar dependencias locales
# -----------------------------------------------------------------------------
DEPENDENCIES=("logging.sh" "validation.sh")

for file in "${DEPENDENCIES[@]}"; do
    FULL_PATH="${SCRIPT_DIR}/${file}"
    if [[ -f "$FULL_PATH" ]]; then
        source "$FULL_PATH"
        echo "Cargado: $FULL_PATH"
    else
        echo "Advertencia: No se encontró $FULL_PATH"
    fi
done

# -----------------------------------------------------------------------------
# Cargar configuración si existe
# -----------------------------------------------------------------------------
CONFIG_FILE="${SCRIPT_DIR}/../config/versions.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    echo "Configuración cargada desde $CONFIG_FILE"
else
    echo "Advertencia: No se encontró archivo de configuración en $CONFIG_FILE"
fi

# -----------------------------------------------------------------------------
# OS Detection
# -----------------------------------------------------------------------------

# Detect OS version and set variables
detect_os_version() {
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot detect OS: /etc/os-release not found"
        return 1
    fi
    
    source /etc/os-release
    
    export OS_ID="$ID"
    export OS_VERSION="$VERSION_ID"
    export OS_CODENAME="$VERSION_CODENAME"
    export OS_PRETTY_NAME="$PRETTY_NAME"
    
    log_debug "OS detected: $OS_PRETTY_NAME"
    return 0
}

# Check if system is Debian-based
is_debian_based() {
    detect_os_version
    [[ "$OS_ID" =~ ^(ubuntu|debian)$ ]]
}

# Check if system is RedHat-based
is_redhat_based() {
    detect_os_version
    [[ "$OS_ID" =~ ^(centos|rhel|fedora)$ ]]
}

# -----------------------------------------------------------------------------
# Package Management
# -----------------------------------------------------------------------------

# Update package lists
update_package_lists() {
    log_info "Updating package lists..."
    
    if is_debian_based; then
        sudo apt-get update -qq || {
            log_error "Failed to update package lists"
            return 1
        }
    elif is_redhat_based; then
        sudo yum makecache -q || {
            log_error "Failed to update package lists"
            return 1
        }
    else
        log_error "Unsupported package manager"
        return 1
    fi
    
    log_success "Package lists updated"
    return 0
}

# Install packages
install_packages() {
    local packages=("$@")
    
    if [ ${#packages[@]} -eq 0 ]; then
        log_warn "No packages specified for installation"
        return 0
    fi
    
    log_info "Installing packages: ${packages[*]}"
    
    if is_debian_based; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${packages[@]}" || {
            log_error "Failed to install packages"
            return 1
        }
    elif is_redhat_based; then
        sudo yum install -y -q "${packages[@]}" || {
            log_error "Failed to install packages"
            return 1
        }
    else
        log_error "Unsupported package manager"
        return 1
    fi
    
    log_success "Packages installed successfully"
    return 0
}

# Check if package is installed
is_package_installed() {
    local package="$1"
    
    if is_debian_based; then
        dpkg -l "$package" 2>/dev/null | grep -q "^ii"
    elif is_redhat_based; then
        rpm -q "$package" &>/dev/null
    else
        return 1
    fi
}

# -----------------------------------------------------------------------------
# File Operations
# -----------------------------------------------------------------------------

# Create directory with proper permissions
create_directory() {
    local dir="$1"
    local mode="${2:-755}"
    local owner="${3:-$USER}"
    
    if [ -d "$dir" ]; then
        log_debug "Directory already exists: $dir"
        return 0
    fi
    
    mkdir -p "$dir" || {
        log_error "Failed to create directory: $dir"
        return 1
    }
    
    chmod "$mode" "$dir" || {
        log_warn "Failed to set permissions on $dir"
    }
    
    if [ -n "$owner" ] && [ "$owner" != "$USER" ]; then
        sudo chown "$owner:$owner" "$dir" || {
            log_warn "Failed to set owner on $dir"
        }
    fi
    
    log_debug "Directory created: $dir"
    return 0
}

# Download file with fallback (wget/curl)
download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-File}"
    
    if ! validate_url "$url"; then
        return 1
    fi
    
    log_info "Downloading $description..."
    log_debug "URL: $url"
    log_debug "Output: $output"
    
    # Try curl first
    if command -v curl &>/dev/null; then
        if curl -fsSL -o "$output" "$url"; then
            log_success "$description downloaded"
            return 0
        fi
    fi
    
    # Fallback to wget
    if command -v wget &>/dev/null; then
        if wget -q -O "$output" "$url"; then
            log_success "$description downloaded"
            return 0
        fi
    fi
    
    log_error "Failed to download $description (tried curl and wget)"
    return 1
}

# Download file with progress
download_file_with_progress() {
    local url="$1"
    local output="$2"
    local description="${3:-File}"
    
    if ! validate_url "$url"; then
        return 1
    fi
    
    log_info "Downloading $description..."
    
    # Try curl with progress
    if command -v curl &>/dev/null; then
        if curl -L --progress-bar -o "$output" "$url"; then
            log_success "$description downloaded"
            return 0
        fi
    fi
    
    # Fallback to wget with progress
    if command -v wget &>/dev/null; then
        if wget --show-progress -O "$output" "$url"; then
            log_success "$description downloaded"
            return 0
        fi
    fi
    
    log_error "Failed to download $description"
    return 1
}

# Extract tarball
extract_tarball() {
    local archive="$1"
    local destination="${2:-.}"
    local description="${3:-Archive}"
    
    if ! validate_file_exists "$archive" "$description"; then
        return 1
    fi
    
    log_info "Extracting $description..."
    
    # Detect archive type and extract
    case "$archive" in
        *.tar.gz|*.tgz)
            tar -xzf "$archive" -C "$destination" || {
                log_error "Failed to extract $description"
                return 1
            }
            ;;
        *.tar.bz2|*.tbz2)
            tar -xjf "$archive" -C "$destination" || {
                log_error "Failed to extract $description"
                return 1
            }
            ;;
        *.tar.xz|*.txz)
            tar -xJf "$archive" -C "$destination" || {
                log_error "Failed to extract $description"
                return 1
            }
            ;;
        *.zip)
            if ! command -v unzip &>/dev/null; then
                log_error "unzip not available"
                return 1
            fi
            unzip -q "$archive" -d "$destination" || {
                log_error "Failed to extract $description"
                return 1
            }
            ;;
        *)
            log_error "Unsupported archive format: $archive"
            return 1
            ;;
    esac
    
    log_success "$description extracted"
    return 0
}

# Create backup of file
backup_file() {
    local file="$1"
    local backup_suffix="${2:-.backup.$(date +%Y%m%d_%H%M%S)}"
    
    if ! validate_file_exists "$file"; then
        return 1
    fi
    
    local backup_file="${file}${backup_suffix}"
    
    cp "$file" "$backup_file" || {
        log_error "Failed to create backup: $backup_file"
        return 1
    }
    
    log_success "Backup created: $backup_file"
    return 0
}

# -----------------------------------------------------------------------------
# Temporary Files
# -----------------------------------------------------------------------------

# Create temporary directory
create_temp_dir() {
    local prefix="${1:-vpn-proxy-agent}"
    
    local temp_dir=$(mktemp -d -t "${prefix}.XXXXXXXXXX") || {
        log_error "Failed to create temporary directory"
        return 1
    }
    
    log_debug "Temporary directory created: $temp_dir"
    echo "$temp_dir"
    return 0
}

# Cleanup temporary directory
cleanup_temp_dir() {
    local temp_dir="$1"
    
    if [ -z "$temp_dir" ]; then
        log_warn "No temp directory specified for cleanup"
        return 0
    fi
    
    if [ ! -d "$temp_dir" ]; then
        log_debug "Temp directory does not exist: $temp_dir"
        return 0
    fi
    
    # Safety check: ensure it's in /tmp
    if [[ "$temp_dir" != /tmp/* ]] && [[ "$temp_dir" != /var/tmp/* ]]; then
        log_error "Refusing to delete directory outside /tmp: $temp_dir"
        return 1
    fi
    
    rm -rf "$temp_dir" || {
        log_warn "Failed to cleanup temp directory: $temp_dir"
        return 1
    }
    
    log_debug "Temp directory cleaned up: $temp_dir"
    return 0
}

# Register cleanup trap
register_cleanup_trap() {
    local temp_dir="$1"
    trap "cleanup_temp_dir '$temp_dir'" EXIT INT TERM
}

# -----------------------------------------------------------------------------
# Process Management
# -----------------------------------------------------------------------------

# Check if process is running
is_process_running() {
    local process_name="$1"
    pgrep -x "$process_name" >/dev/null 2>&1
}

# Wait for process to finish
wait_for_process() {
    local pid="$1"
    local timeout="${2:-300}"  # Default 5 minutes
    local elapsed=0
    
    while kill -0 "$pid" 2>/dev/null; do
        if [ $elapsed -ge $timeout ]; then
            log_error "Timeout waiting for process $pid"
            return 1
        fi
        sleep 1
        ((elapsed++))
    done
    
    return 0
}

# -----------------------------------------------------------------------------
# Service Management
# -----------------------------------------------------------------------------

# Check if systemd service is active
is_service_active() {
    local service="$1"
    systemctl is-active --quiet "$service"
}

# Enable and start service
enable_service() {
    local service="$1"
    
    sudo systemctl enable "$service" || {
        log_error "Failed to enable service: $service"
        return 1
    }
    
    sudo systemctl start "$service" || {
        log_error "Failed to start service: $service"
        return 1
    }
    
    log_success "Service enabled and started: $service"
    return 0
}

# Restart service
restart_service() {
    local service="$1"
    
    sudo systemctl restart "$service" || {
        log_error "Failed to restart service: $service"
        return 1
    }
    
    log_success "Service restarted: $service"
    return 0
}

# -----------------------------------------------------------------------------
# String Utilities
# -----------------------------------------------------------------------------

# Trim whitespace from string
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"  # Remove leading whitespace
    var="${var%"${var##*[![:space:]]}"}"  # Remove trailing whitespace
    echo "$var"
}

# Convert string to lowercase
to_lowercase() {
    echo "$*" | tr '[:upper:]' '[:lower:]'
}

# Convert string to uppercase
to_uppercase() {
    echo "$*" | tr '[:lower:]' '[:upper:]'
}

# Replace spaces with underscores
slugify() {
    echo "$*" | tr ' ' '_' | tr '[:upper:]' '[:lower:]'
}

# -----------------------------------------------------------------------------
# Artifact Naming
# -----------------------------------------------------------------------------

# Generate artifact name
get_artifact_name() {
    local component="$1"
    local version="$2"
    local extension="${3:-.tar.gz}"
    
    echo "${component}-${version}${extension}"
}

# Get Python artifact name
get_python_artifact_name() {
    local version="${1:-$DEFAULT_PYTHON_VERSION}"
    echo "Python-${version}.tgz"
}

# -----------------------------------------------------------------------------
# Configuration Management
# -----------------------------------------------------------------------------

# Load environment file
load_env_file() {
    local env_file="$1"
    
    if ! validate_file_exists "$env_file" ".env file"; then
        return 1
    fi
    
    set -a  # Automatically export all variables
    source "$env_file"
    set +a
    
    log_debug "Environment file loaded: $env_file"
    return 0
}

# Get configuration value
get_config_value() {
    local key="$1"
    local config_file="${2:-$CONFIG_FILE}"
    local default="$3"
    
    if [ ! -f "$config_file" ]; then
        echo "$default"
        return 1
    fi
    
    local value=$(grep "^${key}=" "$config_file" | cut -d'=' -f2- | tr -d '"')
    
    if [ -z "$value" ]; then
        echo "$default"
        return 1
    fi
    
    echo "$value"
    return 0
}

# Export functions
export -f detect_os_version
export -f is_debian_based
export -f is_redhat_based
export -f update_package_lists
export -f install_packages
export -f is_package_installed
export -f create_directory
export -f download_file
export -f download_file_with_progress
export -f extract_tarball
export -f backup_file
export -f create_temp_dir
export -f cleanup_temp_dir
export -f register_cleanup_trap
export -f is_process_running
export -f wait_for_process
export -f is_service_active
export -f enable_service
export -f restart_service
export -f trim
export -f to_lowercase
export -f to_uppercase
export -f slugify
export -f get_artifact_name
export -f get_python_artifact_name
export -f load_env_file
export -f get_config_value

#!/bin/bash

# =============================================================================
# VPN/Proxy Agent - Validation Utility
# =============================================================================
# Description: Common validation functions
# Usage: source utils/validation.sh
# =============================================================================

VALIDATION_UTILS_PATH="${BASH_SOURCE[0]:-$0}"
VALIDATION_UTILS_DIR="$(cd "$(dirname "$VALIDATION_UTILS_PATH")" && pwd)"

LOGGING_FILE="${VALIDATION_UTILS_DIR}/logging.sh"
if [[ -f "$LOGGING_FILE" ]]; then
    source "$LOGGING_FILE"
else
    echo "Advertencia: No se encontró $LOGGING_FILE"
fi

# -----------------------------------------------------------------------------
# Command Validation
# -----------------------------------------------------------------------------

# Check if command exists
validate_command_exists() {
    local cmd="$1"
    local package_name="${2:-$1}"  # Default to command name if not specified
    
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Command '$cmd' not found. Please install: $package_name"
        return 1
    fi
    log_debug "Command '$cmd' is available"
    return 0
}

# Check multiple commands
validate_commands_exist() {
    local all_valid=true
    
    for cmd in "$@"; do
        if ! validate_command_exists "$cmd"; then
            all_valid=false
        fi
    done
    
    if [ "$all_valid" = false ]; then
        return 1
    fi
    return 0
}

# -----------------------------------------------------------------------------
# Python Version Validation
# -----------------------------------------------------------------------------

# Validate Python version format (X.Y.Z)
validate_python_version_format() {
    local version="$1"
    
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid Python version format: $version (expected X.Y.Z)"
        return 1
    fi
    
    log_debug "Python version format valid: $version"
    return 0
}

# Check if Python version is supported
validate_python_version_supported() {
    local version="$1"
    
    if [ -z "${SUPPORTED_PYTHON_VERSIONS}" ]; then
        log_warn "SUPPORTED_PYTHON_VERSIONS not defined, skipping validation"
        return 0
    fi
    
    for supported in "${SUPPORTED_PYTHON_VERSIONS[@]}"; do
        if [ "$version" = "$supported" ]; then
            log_debug "Python version $version is supported"
            return 0
        fi
    done
    
    log_error "Python version $version is not in supported list: ${SUPPORTED_PYTHON_VERSIONS[*]}"
    return 1
}

# Validate installed Python version
validate_python_installation() {
    local python_cmd="${1:-python3}"
    local expected_version="$2"
    
    if ! validate_command_exists "$python_cmd"; then
        return 1
    fi
    
    local installed_version=$($python_cmd --version 2>&1 | awk '{print $2}')
    
    if [ -n "$expected_version" ] && [ "$installed_version" != "$expected_version" ]; then
        log_error "Python version mismatch. Expected: $expected_version, Found: $installed_version"
        return 1
    fi
    
    log_success "Python $installed_version is installed"
    return 0
}

# -----------------------------------------------------------------------------
# File Validation
# -----------------------------------------------------------------------------

# Check if file exists
validate_file_exists() {
    local file="$1"
    local description="${2:-File}"
    
    if [ ! -f "$file" ]; then
        log_error "$description not found: $file"
        return 1
    fi
    
    log_debug "$description exists: $file"
    return 0
}

# Check if directory exists
validate_directory_exists() {
    local dir="$1"
    local description="${2:-Directory}"
    
    if [ ! -d "$dir" ]; then
        log_error "$description not found: $dir"
        return 1
    fi
    
    log_debug "$description exists: $dir"
    return 0
}

# Validate file is readable
validate_file_readable() {
    local file="$1"
    
    if [ ! -r "$file" ]; then
        log_error "File is not readable: $file"
        return 1
    fi
    
    return 0
}

# Validate file is writable
validate_file_writable() {
    local file="$1"
    
    if [ ! -w "$file" ]; then
        log_error "File is not writable: $file"
        return 1
    fi
    
    return 0
}

# Validate file is executable
validate_file_executable() {
    local file="$1"
    
    if [ ! -x "$file" ]; then
        log_error "File is not executable: $file"
        return 1
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# Checksum Validation
# -----------------------------------------------------------------------------

# Validate SHA256 checksum
validate_checksum() {
    local file="$1"
    local expected_checksum="$2"
    
    if ! validate_file_exists "$file"; then
        return 1
    fi
    
    if ! validate_command_exists "sha256sum" "coreutils"; then
        log_warn "sha256sum not available, skipping checksum validation"
        return 0
    fi
    
    local actual_checksum=$(sha256sum "$file" | awk '{print $1}')
    
    if [ "$actual_checksum" != "$expected_checksum" ]; then
        log_error "Checksum mismatch for $file"
        log_error "Expected: $expected_checksum"
        log_error "Actual:   $actual_checksum"
        return 1
    fi
    
    log_success "Checksum valid for $file"
    return 0
}

# Validate MD5 checksum
validate_md5() {
    local file="$1"
    local expected_md5="$2"
    
    if ! validate_file_exists "$file"; then
        return 1
    fi
    
    if ! validate_command_exists "md5sum" "coreutils"; then
        log_warn "md5sum not available, skipping MD5 validation"
        return 0
    fi
    
    local actual_md5=$(md5sum "$file" | awk '{print $1}')
    
    if [ "$actual_md5" != "$expected_md5" ]; then
        log_error "MD5 mismatch for $file"
        log_error "Expected: $expected_md5"
        log_error "Actual:   $actual_md5"
        return 1
    fi
    
    log_success "MD5 valid for $file"
    return 0
}

# -----------------------------------------------------------------------------
# Network Validation
# -----------------------------------------------------------------------------

# Validate port number
validate_port() {
    local port="$1"
    local description="${2:-Port}"

    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log_error "$description invalid: $port (must be 1-65535)"
        return 1
    fi

    log_debug "$description valid: $port"
    return 0
}

# Determine if a port is free for use without emitting user-facing errors
is_port_available() {
    local port="$1"

    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi

    if command -v ss >/dev/null 2>&1; then
        if ss -H -ltn "sport = :$port" 2>/dev/null | grep -q '[^[:space:]]'; then
            return 1
        fi
        if ss -H -lun "sport = :$port" 2>/dev/null | grep -q '[^[:space:]]'; then
            return 1
        fi
        return 0
    fi

    if command -v lsof >/dev/null 2>&1; then
        if lsof -nP -i ":$port" 2>/dev/null | grep -q '[^[:space:]]'; then
            return 1
        fi
        return 0
    fi

    if command -v netstat >/dev/null 2>&1; then
        if netstat -tuln 2>/dev/null | awk '{print $4}' | grep -qE "[:.]$port$"; then
            return 1
        fi
        return 0
    fi

    return 0
}

# Validate IP address format
validate_ip() {
    local ip="$1"
    local description="${2:-IP address}"
    
    if ! [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        log_error "$description invalid format: $ip"
        return 1
    fi
    
    # Validate each octet
    IFS='.' read -r -a octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [ "$octet" -gt 255 ]; then
            log_error "$description invalid: $ip (octet $octet > 255)"
            return 1
        fi
    done
    
    log_debug "$description valid: $ip"
    return 0
}

# Check if port is available
validate_port_available() {
    local port="$1"
    
    if ! validate_port "$port"; then
        return 1
    fi
    
    if ! is_port_available "$port"; then
        log_error "Port $port is already in use"
        return 1
    fi

    log_debug "Port $port is available"
    return 0
}

# Validate URL format
validate_url() {
    local url="$1"
    local description="${2:-URL}"
    
    if ! [[ "$url" =~ ^https?:// ]]; then
        log_error "$description invalid format: $url (must start with http:// or https://)"
        return 1
    fi
    
    log_debug "$description valid: $url"
    return 0
}

# Test connectivity to URL
validate_url_reachable() {
    local url="$1"
    local timeout="${2:-5}"
    
    if ! validate_command_exists "curl"; then
        log_warn "curl not available, skipping reachability test"
        return 0
    fi
    
    if ! curl -sf --max-time "$timeout" "$url" > /dev/null 2>&1; then
        log_error "URL not reachable: $url"
        return 1
    fi
    
    log_success "URL reachable: $url"
    return 0
}

# -----------------------------------------------------------------------------
# System Validation
# -----------------------------------------------------------------------------

# Validate Ubuntu version
validate_ubuntu_version() {
    local required_version="${1:-$UBUNTU_VERSION}"
    
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot determine OS version (/etc/os-release not found)"
        return 1
    fi
    
    source /etc/os-release
    
    if [ "$ID" != "ubuntu" ]; then
        log_error "This system is not Ubuntu (detected: $ID)"
        return 1
    fi
    
    if [ -n "$required_version" ] && [ "$VERSION_ID" != "$required_version" ]; then
        log_warn "Ubuntu version mismatch. Expected: $required_version, Found: $VERSION_ID"
        # Don't return error, just warn
    fi
    
    log_info "Ubuntu $VERSION_ID detected"
    return 0
}

# Check if running as root
validate_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root (use sudo)"
        return 1
    fi
    return 0
}

# Check if NOT running as root
validate_not_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "This script should NOT be run as root"
        return 1
    fi
    return 0
}

# Validate minimum disk space
validate_disk_space() {
    local path="${1:-.}"
    local required_mb="$2"
    
    local available_kb=$(df "$path" | awk 'NR==2 {print $4}')
    local available_mb=$((available_kb / 1024))
    
    if [ "$available_mb" -lt "$required_mb" ]; then
        log_error "Insufficient disk space in $path"
        log_error "Required: ${required_mb}MB, Available: ${available_mb}MB"
        return 1
    fi
    
    log_debug "Sufficient disk space: ${available_mb}MB available"
    return 0
}

# Validate minimum RAM
validate_ram() {
    local required_mb="$1"
    
    local available_mb=$(free -m | awk 'NR==2 {print $2}')
    
    if [ "$available_mb" -lt "$required_mb" ]; then
        log_error "Insufficient RAM"
        log_error "Required: ${required_mb}MB, Available: ${available_mb}MB"
        return 1
    fi
    
    log_debug "Sufficient RAM: ${available_mb}MB available"
    return 0
}

# -----------------------------------------------------------------------------
# Python Module Validation
# -----------------------------------------------------------------------------

# Check if Python module is installed
validate_python_module() {
    local python_cmd="${1:-python3}"
    local module="$2"
    
    if ! $python_cmd -c "import $module" 2>/dev/null; then
        log_error "Python module '$module' not found"
        return 1
    fi
    
    log_debug "Python module '$module' is installed"
    return 0
}

# Check multiple Python modules
validate_python_modules() {
    local python_cmd="$1"
    shift
    local modules=("$@")
    
    local all_valid=true
    
    for module in "${modules[@]}"; do
        if ! validate_python_module "$python_cmd" "$module"; then
            all_valid=false
        fi
    done
    
    if [ "$all_valid" = false ]; then
        return 1
    fi
    return 0
}

# Export functions
export -f validate_command_exists
export -f validate_commands_exist
export -f validate_python_version_format
export -f validate_python_version_supported
export -f validate_python_installation
export -f validate_file_exists
export -f validate_directory_exists
export -f validate_file_readable
export -f validate_file_writable
export -f validate_file_executable
export -f validate_checksum
export -f validate_md5
export -f validate_port
export -f is_port_available
export -f validate_ip
export -f validate_port_available
export -f validate_url
export -f validate_url_reachable
export -f validate_ubuntu_version
export -f validate_root
export -f validate_not_root
export -f validate_disk_space
export -f validate_ram
export -f validate_python_module
export -f validate_python_modules

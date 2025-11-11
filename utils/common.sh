#!/bin/bash
# =============================================================================
# VPN/Proxy Agent - Common Utilities
# =============================================================================
# Description: Common helper functions used across scripts
# Usage: source utils/common.sh
# =============================================================================

COMMON_UTILS_PATH="${BASH_SOURCE[0]:-$0}"
COMMON_UTILS_DIR="$(cd "$(dirname "$COMMON_UTILS_PATH")" && pwd)"

DEPENDENCIES=("logging.sh" "validation.sh")

for file in "${DEPENDENCIES[@]}"; do
    FULL_PATH="${COMMON_UTILS_DIR}/${file}"
    if [[ -f "$FULL_PATH" ]]; then
        source "$FULL_PATH"
    else
        echo "Advertencia: No se encontró $FULL_PATH"
    fi
done

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
        sudo apt-get clean -qq || {
            log_warn "Failed to clean apt cache"
        }
        sudo rm -rf /var/lib/apt/lists/* || {
            log_warn "Failed to remove cached apt lists"
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

# Create compressed archive from provided sources while validating them
create_tarball() {
    local output="$1"
    local description="$2"
    shift 2
    local sources=("$@")
    local existing_sources=()
    local missing_sources=()

    if [ -z "$output" ] || [ -z "$description" ]; then
        log_error "create_tarball requires an output path and description"
        return 1
    fi

    for path in "${sources[@]}"; do
        if [ -e "$path" ]; then
            existing_sources+=("$path")
        else
            missing_sources+=("$path")
        fi
    done

    if [ ${#existing_sources[@]} -eq 0 ]; then
        log_error "No valid sources found for $description archive"
        return 1
    fi

    if [ ${#missing_sources[@]} -gt 0 ]; then
        log_warn "Skipping missing sources for $description: ${missing_sources[*]}"
    fi

    local output_dir
    output_dir="$(dirname "$output")"
    create_directory "$output_dir"

    if tar -czf "$output" "${existing_sources[@]}"; then
        log_success "$description archive created: $output"
        return 0
    fi

    log_error "Failed to create $description archive at $output"
    return 1
}

# -----------------------------------------------------------------------------
# Runtime Toolchain Helpers
# -----------------------------------------------------------------------------

configure_language_runtimes() {
    local config_path="${1:-${HOME}/.config/mise/config.toml}"
    local -a toolchain_entries=("${MCP_RUNTIME_TOOLCHAIN[@]-}")

    if [ ${#toolchain_entries[@]} -eq 0 ]; then
        log_warn "No runtime toolchain entries defined. Skipping language runtime configuration."
        return 0
    fi

    if [ "${LANGUAGE_TOOLCHAIN_SUPPRESS_HEADER:-0}" != "1" ]; then
        log_section "Configuring language runtimes"
    fi

    local config_dir
    config_dir="$(dirname "$config_path")"
    mkdir -p "$config_dir"

    local tmp_config
    tmp_config="$(mktemp)"

    {
        echo "[tools]"
        local entry
        for entry in "${toolchain_entries[@]}"; do
            local tool_name display_name version default_version
            IFS='|' read -r tool_name display_name version default_version <<< "$entry"
            if [ -z "$tool_name" ] || [ -z "$version" ]; then
                log_warn "Skipping invalid runtime entry: $entry"
                continue
            fi
            echo "${tool_name} = \"${version}\""
        done
    } >"$tmp_config"

    install -m 644 "$tmp_config" "$config_path"
    rm -f "$tmp_config"

    log_info "mise configuration written to ${config_path}"

    local has_mise=1
    if ! command -v mise >/dev/null 2>&1; then
        has_mise=0
        log_warn "mise command not found. Logging desired activations for manual execution."
    fi

    local entry
    for entry in "${toolchain_entries[@]}"; do
        local tool_name display_name version default_version
        IFS='|' read -r tool_name display_name version default_version <<< "$entry"
        if [ -z "$tool_name" ] || [ -z "$version" ]; then
            continue
        fi

        if [ -z "$display_name" ]; then
            display_name="$tool_name"
        fi

        local descriptor="# ${display_name}: ${version}"
        if [ -n "$default_version" ]; then
            descriptor+=" (default: ${default_version})"
        fi
        log_info "$descriptor"

        log_info "mise ${config_path} tools: ${tool_name}@${version}"

        if [ $has_mise -eq 1 ]; then
            if ! mise use -g "${tool_name}@${version}" >/dev/null 2>&1; then
                log_warn "mise failed to activate ${tool_name}@${version}"
            fi
        fi
    done

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

# Ensure systemd-resolved frees the DNS stub listener so SSH can bind to port 53
ensure_dns_stub_listener_disabled() {
    local port="${1:-53}"
    local resolved_conf="${SYSTEMD_RESOLVED_CONF_PATH:-/etc/systemd/resolved.conf}"
    local resolv_conf_path="${DNS_RESOLV_CONF_PATH:-/etc/resolv.conf}"
    local fallback_resolv="${SYSTEMD_RESOLVED_FALLBACK_PATH:-/run/systemd/resolve/resolv.conf}"
    local sudo_prefix=""

    if command -v sudo >/dev/null 2>&1; then
        sudo_prefix="sudo"
    fi

    if is_port_available "$port"; then
        log_debug "Port $port already available; no DNS stub listener adjustments required"
        return 0
    fi

    if ! command -v systemctl >/dev/null 2>&1; then
        log_warn "systemctl is unavailable; cannot adjust systemd-resolved for port $port"
        return 1
    fi

    if ! systemctl is-active --quiet systemd-resolved; then
        log_debug "systemd-resolved is not active; skipping DNS stub listener adjustments"
        return 0
    fi

    if [ ! -f "$resolved_conf" ]; then
        log_warn "systemd-resolved configuration not found at $resolved_conf"
        return 1
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        log_warn "python3 is required to adjust $resolved_conf; skipping DNS stub listener changes"
        return 1
    fi

    log_info "Disabling systemd-resolved stub listener to free port $port"

    local temp_copy
    temp_copy="$(mktemp)"

    if ! cp "$resolved_conf" "$temp_copy" 2>/dev/null; then
        if [ -n "$sudo_prefix" ]; then
            $sudo_prefix cp "$resolved_conf" "$temp_copy" || {
                log_error "Failed to copy $resolved_conf for modification"
                rm -f "$temp_copy"
                return 1
            }
        else
            log_error "Failed to copy $resolved_conf for modification"
            rm -f "$temp_copy"
            return 1
        fi
    fi

    if ! python3 - "$temp_copy" <<'PY'; then
from pathlib import Path
import sys

path = Path(sys.argv[1])
content = path.read_text().splitlines()
added = False
resolve_index = None

for idx, line in enumerate(content):
    if line.strip().lower().startswith('dnsstublistener'):
        content[idx] = 'DNSStubListener=no'
        added = True
        break

for idx, line in enumerate(content):
    if line.strip() == '[Resolve]':
        resolve_index = idx
        break

if not added:
    if resolve_index is not None:
        content.insert(resolve_index + 1, 'DNSStubListener=no')
        added = True

if not added:
    content.extend(['[Resolve]', 'DNSStubListener=no'])

path.write_text('\n'.join(content) + '\n')
PY
        log_error "Failed to update DNSStubListener configuration in $resolved_conf"
        rm -f "$temp_copy"
        return 1
    fi

    if ! cp "$temp_copy" "$resolved_conf" 2>/dev/null; then
        if [ -n "$sudo_prefix" ]; then
            $sudo_prefix cp "$temp_copy" "$resolved_conf" || {
                log_error "Failed to persist DNS stub listener changes to $resolved_conf"
                rm -f "$temp_copy"
                return 1
            }
        else
            log_error "Failed to persist DNS stub listener changes to $resolved_conf"
            rm -f "$temp_copy"
            return 1
        fi
    fi

    rm -f "$temp_copy"

    if [ -n "$fallback_resolv" ] && [ -f "$fallback_resolv" ]; then
        local needs_link=1
        if [ -L "$resolv_conf_path" ]; then
            local current_target
            current_target="$(readlink "$resolv_conf_path")"
            if [ "$current_target" = "$fallback_resolv" ]; then
                needs_link=0
            fi
        fi

        if [ $needs_link -eq 1 ]; then
            log_info "Pointing $resolv_conf_path to $fallback_resolv for DNS resolution"
            if ! ln -sf "$fallback_resolv" "$resolv_conf_path" 2>/dev/null; then
                if [ -n "$sudo_prefix" ]; then
                    $sudo_prefix ln -sf "$fallback_resolv" "$resolv_conf_path" || {
                        log_warn "Failed to link $resolv_conf_path to $fallback_resolv"
                    }
                else
                    log_warn "Failed to link $resolv_conf_path to $fallback_resolv"
                fi
            fi
        fi
    else
        log_warn "Fallback resolver file $fallback_resolv not found; writing placeholder resolv.conf"
        if ! printf 'nameserver 1.1.1.1\n' >"$resolv_conf_path" 2>/dev/null; then
            if [ -n "$sudo_prefix" ]; then
                printf 'nameserver 1.1.1.1\n' | $sudo_prefix tee "$resolv_conf_path" >/dev/null || {
                    log_warn "Failed to write placeholder resolv.conf at $resolv_conf_path"
                }
            else
                log_warn "Failed to write placeholder resolv.conf at $resolv_conf_path"
            fi
        fi
    fi

    if [ -n "$sudo_prefix" ]; then
        $sudo_prefix systemctl restart systemd-resolved || {
            log_error "Failed to restart systemd-resolved after disabling stub listener"
            return 1
        }
    else
        systemctl restart systemd-resolved || {
            log_error "Failed to restart systemd-resolved after disabling stub listener"
            return 1
        }
    fi

    log_success "systemd-resolved stub listener disabled for port $port"
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

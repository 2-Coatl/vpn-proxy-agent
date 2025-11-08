#!/bin/bash
# =============================================================================
# VPN/Proxy Agent - Logging Utility
# =============================================================================
# Description: Centralized logging functions with consistent formatting
# Usage: source utils/logging.sh
# =============================================================================
# -----------------------------------------------------------------------------
# Determinar la ruta absoluta del directorio de este script
# -----------------------------------------------------------------------------
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# -----------------------------------------------------------------------------
# Cargar configuración si existe
# -----------------------------------------------------------------------------
CONFIG_FILE="${SCRIPT_DIR}/../config/versions.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    echo "Configuración de colores cargada desde $CONFIG_FILE"
else
    echo "Advertencia: No se encontró configuración en $CONFIG_FILE. Usando colores por defecto."

    # Colores por defecto
    COLOR_RESET="\033[0m"
    COLOR_RED="\033[0;31m"
    COLOR_GREEN="\033[0;32m"
    COLOR_YELLOW="\033[0;33m"
    COLOR_BLUE="\033[0;34m"
    COLOR_BOLD="\033[1m"
fi

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------

# Log informational message
log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

# Log success message
log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*"
}

# Log warning message
log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"
}

# Log error message
log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

# Log step in a process (numbered)
log_step() {
    local step_num="$1"
    shift
    echo -e "${COLOR_BOLD}[STEP $step_num]${COLOR_RESET} $*"
}

# Log section header
log_header() {
    echo ""
    echo "=============================================="
    echo "  $*"
    echo "=============================================="
    echo ""
}

# Log subsection
log_section() {
    echo ""
    echo "--- $* ---"
}

# Log debug message (only if DEBUG=1)
log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        echo -e "${COLOR_BLUE}[DEBUG]${COLOR_RESET} $*"
    fi
}

# Log to file and stdout
log_file() {
    local log_file="$1"
    shift
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$message" | tee -a "$log_file"
}

# Log command execution
log_command() {
    local cmd="$*"
    log_debug "Executing: $cmd"
    eval "$cmd"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Command failed with exit code $exit_code: $cmd"
    fi
    return $exit_code
}

# Progress indicator
log_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    local percent=$((current * 100 / total))
    echo -ne "\r${COLOR_BLUE}[PROGRESS]${COLOR_RESET} $message... $percent% ($current/$total)"
    if [ "$current" -eq "$total" ]; then
        echo ""  # New line when complete
    fi
}

# Spinner animation
spin() {
    local pid=$1
    local message="${2:-Processing}"
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c] %s" "$spinstr" "$message"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b\b"
        for ((i=0; i<${#message}; i++)); do
            printf "\b"
        done
    done
    printf "    \b\b\b\b"
}

# Confirm action (returns 0 for yes, 1 for no)
log_confirm() {
    local message="$1"
    local default="${2:-n}"  # Default to 'n' if not specified
    
    if [ "$default" = "y" ]; then
        local prompt="[Y/n]"
    else
        local prompt="[y/N]"
    fi
    
    echo -ne "${COLOR_YELLOW}[CONFIRM]${COLOR_RESET} $message $prompt "
    read -r response
    response=${response,,}  # Convert to lowercase
    
    if [ -z "$response" ]; then
        response="$default"
    fi
    
    if [[ "$response" =~ ^(yes|y)$ ]]; then
        return 0
    else
        return 1
    fi
}

# Show a box around text
log_box() {
    local text="$1"
    local length=${#text}
    local border=""
    
    for ((i=0; i<length+4; i++)); do
        border="${border}="
    done
    
    echo ""
    echo "$border"
    echo "  $text"
    echo "$border"
    echo ""
}

# Log summary table
log_summary_start() {
    echo ""
    echo "======================================"
    echo "  SUMMARY"
    echo "======================================"
}

log_summary_item() {
    local key="$1"
    local value="$2"
    printf "  %-25s : %s\n" "$key" "$value"
}

log_summary_end() {
    echo "======================================"
    echo ""
}

# Execution time tracker
declare -A _START_TIMES

start_timer() {
    local timer_name="${1:-default}"
    _START_TIMES[$timer_name]=$(date +%s)
}

end_timer() {
    local timer_name="${1:-default}"
    local message="${2:-Operation}"
    
    if [ -z "${_START_TIMES[$timer_name]}" ]; then
        log_warn "Timer '$timer_name' was not started"
        return 1
    fi
    
    local start_time=${_START_TIMES[$timer_name]}
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local hours=$((duration / 3600))
    local minutes=$(( (duration % 3600) / 60 ))
    local seconds=$((duration % 60))
    
    if [ $hours -gt 0 ]; then
        log_info "$message completed in ${hours}h ${minutes}m ${seconds}s"
    elif [ $minutes -gt 0 ]; then
        log_info "$message completed in ${minutes}m ${seconds}s"
    else
        log_info "$message completed in ${seconds}s"
    fi
    
    unset _START_TIMES[$timer_name]
}

# Export functions
export -f log_info
export -f log_success
export -f log_warn
export -f log_error
export -f log_step
export -f log_header
export -f log_section
export -f log_debug
export -f log_file
export -f log_command
export -f log_progress
export -f spin
export -f log_confirm
export -f log_box
export -f log_summary_start
export -f log_summary_item
export -f log_summary_end
export -f start_timer
export -f end_timer

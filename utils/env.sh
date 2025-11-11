#!/bin/bash
# =============================================================================
# Environment Setup - DRY Utility
# =============================================================================
# Description: Centraliza la carga de configuración, validación de rutas y fallback seguro
# Usage: source utils/env.sh
# =============================================================================

# ----------------------------------------------------------------------------- 
# Determinar la ruta absoluta del directorio del script que lo invoca
# ----------------------------------------------------------------------------- 
__ENV_SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
__ENV_SCRIPT_DIR="$(cd "$(dirname "$__ENV_SCRIPT_PATH")" && pwd)"

# -----------------------------------------------------------------------------
# Cargar configuración desde versions.conf
# -----------------------------------------------------------------------------
CONFIG_FILE="${__ENV_SCRIPT_DIR}/../config/versions.conf"
__ENV_REPO_ROOT="$(cd "${__ENV_SCRIPT_DIR}/.." && pwd)"
__ENV_REPO_PROJECT_ROOT="$__ENV_REPO_ROOT"
__ENV_REPO_SCRIPTS_DIR="$__ENV_REPO_ROOT/scripts"
__ENV_REPO_LOGS_DIR="$__ENV_REPO_ROOT/logs"
__ENV_REPO_BACKUPS_DIR="$__ENV_REPO_ROOT/backups"
__ENV_REPO_DATA_DIR="$__ENV_REPO_ROOT/data"

__env_apply_repo_defaults() {
    PROJECT_ROOT="$__ENV_REPO_PROJECT_ROOT"
    SCRIPTS_DIR="$__ENV_REPO_SCRIPTS_DIR"
    LOGS_DIR="$__ENV_REPO_LOGS_DIR"
    BACKUPS_DIR="$__ENV_REPO_BACKUPS_DIR"
    DATA_DIR="$__ENV_REPO_DATA_DIR"
}

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    echo "Configuración cargada desde $CONFIG_FILE"
else
    echo "Advertencia: No se encontró $CONFIG_FILE. Usando rutas locales por defecto."
    __env_apply_repo_defaults
fi

# ----------------------------------------------------------------------------- 
# Fallback si el usuario no es ubuntu
# ----------------------------------------------------------------------------- 
if [[ "$(whoami)" != "ubuntu" ]]; then
    echo "Usuario actual: $(whoami). Redefiniendo rutas para entorno local."
    __env_apply_repo_defaults
fi

# -----------------------------------------------------------------------------
# Validación adicional de rutas críticas
# -----------------------------------------------------------------------------

__ENV_REQUIRED_SCRIPT_CHECKS=(
    "setup_ssh.sh"
    "setup_wireguard.sh"
)

__env_scripts_dir_needs_reset=0

if [[ -z "${SCRIPTS_DIR:-}" || ! -d "$SCRIPTS_DIR" ]]; then
    __env_scripts_dir_needs_reset=1
else
    for required_script in "${__ENV_REQUIRED_SCRIPT_CHECKS[@]}"; do
        if [[ ! -f "${SCRIPTS_DIR}/${required_script}" ]]; then
            __env_scripts_dir_needs_reset=1
            break
        fi
    done
fi

if [[ "$__env_scripts_dir_needs_reset" -eq 1 ]]; then
    echo "Advertencia: SCRIPTS_DIR inválido (${SCRIPTS_DIR:-unset}). Usando ${__ENV_REPO_SCRIPTS_DIR}."
    SCRIPTS_DIR="$__ENV_REPO_SCRIPTS_DIR"
fi

# ----------------------------------------------------------------------------- 
# Validar existencia y permisos de rutas
# ----------------------------------------------------------------------------- 
validate_directory() {
    local dir="$1"
    local label="$2"

    if [[ -z "$dir" ]]; then
        echo "Error: $label no está definido"
        exit 1
    fi

    if [[ ! -d "$dir" ]]; then
        echo "Creando $label: $dir"
        mkdir -p "$dir" || {
            echo "Error: No se pudo crear $label en $dir"
            exit 1
        }
    fi

    if [[ ! -w "$dir" ]]; then
        echo "Error: Sin permisos de escritura en $label: $dir"
        exit 1
    fi
}

validate_directory "$LOGS_DIR" "LOGS_DIR"
validate_directory "$BACKUPS_DIR" "BACKUPS_DIR"
validate_directory "$DATA_DIR" "DATA_DIR"

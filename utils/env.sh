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
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    echo "Configuración cargada desde $CONFIG_FILE"
else
    echo "Advertencia: No se encontró $CONFIG_FILE. Usando rutas locales por defecto."
    PROJECT_ROOT="$__ENV_SCRIPT_DIR"
    SCRIPTS_DIR="$__ENV_SCRIPT_DIR/scripts"
    LOGS_DIR="$__ENV_SCRIPT_DIR/logs"
    BACKUPS_DIR="$__ENV_SCRIPT_DIR/backups"
    DATA_DIR="$__ENV_SCRIPT_DIR/data"
fi

# ----------------------------------------------------------------------------- 
# Fallback si el usuario no es ubuntu
# ----------------------------------------------------------------------------- 
if [[ "$(whoami)" != "ubuntu" ]]; then
    echo "Usuario actual: $(whoami). Redefiniendo rutas para entorno local."
    PROJECT_ROOT="$__ENV_SCRIPT_DIR"
    SCRIPTS_DIR="$__ENV_SCRIPT_DIR/scripts"
    LOGS_DIR="$__ENV_SCRIPT_DIR/logs"
    BACKUPS_DIR="$__ENV_SCRIPT_DIR/backups"
    DATA_DIR="$__ENV_SCRIPT_DIR/data"
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

#!/bin/bash
# =============================================================================
# Environment Setup - DRY Utility
# =============================================================================

# Determinar ruta del script que lo invoca
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Cargar configuración
CONFIG_FILE="${SCRIPT_DIR}/../config/versions.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Advertencia: No se encontró $CONFIG_FILE. Usando rutas locales."
    PROJECT_ROOT="$SCRIPT_DIR"
    SCRIPTS_DIR="$SCRIPT_DIR/scripts"
    LOGS_DIR="$SCRIPT_DIR/logs"
    BACKUPS_DIR="$SCRIPT_DIR/backups"
    DATA_DIR="$SCRIPT_DIR/data"
fi

# Fallback si el usuario no es ubuntu
if [[ "$(whoami)" != "ubuntu" ]]; then
    echo "Usuario actual: $(whoami). Redefiniendo rutas para entorno local."
    PROJECT_ROOT="$SCRIPT_DIR"
    SCRIPTS_DIR="$SCRIPT_DIR/scripts"
    LOGS_DIR="$SCRIPT_DIR/logs"
    BACKUPS_DIR="$SCRIPT_DIR/backups"
    DATA_DIR="$SCRIPT_DIR/data"
fi

# Validar rutas
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

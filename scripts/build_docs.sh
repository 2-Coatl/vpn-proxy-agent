#!/usr/bin/env bash
# =============================================================================
# MkDocs Documentation Builder
# =============================================================================
# Description: Builds the MkDocs site locally without depending on GitHub Actions.
# Usage: ./scripts/build_docs.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/validation.sh"

log_header "Construyendo la documentación con MkDocs"

if ! command -v mkdocs >/dev/null 2>&1; then
    log_error "MkDocs no está instalado. Ejecuta 'make docs-deps' antes de continuar."
    exit 1
fi

log_step 1 2 "Verificando configuración de MkDocs"
if [[ ! -f "${PROJECT_ROOT}/docs/mkdocs.yml" ]]; then
    log_error "No se encontró docs/mkdocs.yml en el repositorio."
    exit 1
fi

log_step 2 2 "Generando el sitio estático"
mkdocs build --config-file docs/mkdocs.yml

log_success "Documentación generada en el directorio 'site/'"

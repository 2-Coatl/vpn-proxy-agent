#!/bin/bash
# Validate Python Build
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/validation.sh"

PYTHON_VERSION="${1:-3.12.6}"
INSTALL_PREFIX="${2:-/opt/python-${PYTHON_VERSION}}"
PYTHON_BIN="${INSTALL_PREFIX}/bin/python${PYTHON_VERSION%.*}"

log_header "Validating Python Build"

# Check binary exists
if ! validate_file_exists "$PYTHON_BIN" "Python binary"; then
    exit 1
fi

# Check version
INSTALLED_VERSION=$("$PYTHON_BIN" --version | awk '{print $2}')
log_info "Installed version: $INSTALLED_VERSION"

if [ "$INSTALLED_VERSION" != "$PYTHON_VERSION" ]; then
    log_error "Version mismatch. Expected: $PYTHON_VERSION, Got: $INSTALLED_VERSION"
    exit 1
fi

# Test basic functionality
log_info "Testing basic functionality..."
"$PYTHON_BIN" -c "print('Hello from Python ${PYTHON_VERSION}')"

# Check modules
log_info "Checking standard modules..."
"$PYTHON_BIN" -c "import ssl, sqlite3, zlib; print('Core modules: OK')"

log_success "Python ${PYTHON_VERSION} validation complete"

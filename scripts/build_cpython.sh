#!/bin/bash
# CPython Build Script
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/validation.sh"
source "${PROJECT_ROOT}/utils/common.sh"

# Configuration
PYTHON_VERSION="${1:-3.12.6}"
BUILD_DIR="/tmp/python-build"
INSTALL_PREFIX="${2:-/opt/python-${PYTHON_VERSION}}"

log_header "Building CPython ${PYTHON_VERSION}"

# Validate version format
if ! validate_python_version_format "$PYTHON_VERSION"; then
    exit 1
fi

# Install build dependencies
log_step 1 5 "Installing build dependencies"
install_packages build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncurses5-dev libncursesw5-dev xz-utils tk-dev \
    libffi-dev liblzma-dev python3-openssl git

# Download Python source
log_step 2 5 "Downloading Python ${PYTHON_VERSION}"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
download_file "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" \
    "Python-${PYTHON_VERSION}.tgz" "Python source"

# Extract
log_step 3 5 "Extracting source"
extract_tarball "Python-${PYTHON_VERSION}.tgz" "$BUILD_DIR"
cd "Python-${PYTHON_VERSION}"

# Configure
log_step 4 5 "Configuring build"
./configure --prefix="$INSTALL_PREFIX" \
    --enable-optimizations \
    --with-lto \
    --enable-shared \
    LDFLAGS="-Wl,-rpath ${INSTALL_PREFIX}/lib"

# Build and install
log_step 5 5 "Building and installing (this may take 10-20 minutes)"
make -j$(nproc)
sudo make altinstall

log_success "Python ${PYTHON_VERSION} installed to ${INSTALL_PREFIX}"
echo ""
echo "Add to PATH:"
echo "  export PATH=\"${INSTALL_PREFIX}/bin:\$PATH\""

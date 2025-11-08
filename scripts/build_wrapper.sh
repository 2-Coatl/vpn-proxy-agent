#!/bin/bash
# Build Wrapper Script
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"

log_header "Python Build Wrapper"

# Check if version specified
if [ -z "$1" ]; then
    log_error "Usage: $0 <python-version>"
    log_info "Example: $0 3.12.6"
    exit 1
fi

# Execute build
"${SCRIPT_DIR}/build_cpython.sh" "$1" "$2"

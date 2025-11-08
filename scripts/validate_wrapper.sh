#!/bin/bash
# Validation Wrapper
set -e

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

"${SCRIPT_DIR}/validate_build.sh" "$@"

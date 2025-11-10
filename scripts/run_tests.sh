#!/bin/bash
# shellcheck shell=bash
# =============================================================================
# VPN/Proxy Agent - Composite Test Runner
# =============================================================================
# Description: Execute Python and shell suites with coverage reporting.
# Usage: ./scripts/run_tests.sh [pytest-args]
# =============================================================================

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARTIFACTS_DIR="${REPO_ROOT}/artifacts"
COVERAGE_DIR="${ARTIFACTS_DIR}/coverage"

mkdir -p "$COVERAGE_DIR"

PYTHON_BIN="${PYTHON:-python3}"
PYTEST_ARGS=("$@")
USE_COVERAGE=1

cd "$REPO_ROOT"

log_phase() {
    local message="$1"
    echo "\n==> $message"
}

ensure_python_tool() {
    local module="$1"
    if "$PYTHON_BIN" -m "$module" --version >/dev/null 2>&1; then
        return 0
    fi

    log_phase "Installing Python module: $module"
    if "$PYTHON_BIN" -m pip install --upgrade "$module"; then
        return 0
    fi

    if [ "$module" = "coverage" ]; then
        log_phase "coverage no disponible; se ejecutará pytest sin métricas"
        USE_COVERAGE=0
        return 0
    fi

    return 1
}

run_python_suite() {
    ensure_python_tool "pytest"
    ensure_python_tool "coverage"

    if (( USE_COVERAGE )); then
        log_phase "Running pytest with coverage"
        "$PYTHON_BIN" -m coverage erase
        "$PYTHON_BIN" -m coverage run -m pytest tests "${PYTEST_ARGS[@]}"
        "$PYTHON_BIN" -m coverage xml -o "${COVERAGE_DIR}/coverage.xml"
        "$PYTHON_BIN" -m coverage html -d "${COVERAGE_DIR}/html"
        "$PYTHON_BIN" -m coverage report --fail-under=80
    else
        log_phase "Running pytest without coverage"
        "$PYTHON_BIN" -m pytest tests "${PYTEST_ARGS[@]}"
    fi
}

run_shell_suite() {
    log_phase "Executing shell regression suite"
    bash tests/test_utilities.sh
}

run_python_suite
run_shell_suite

log_phase "Artifacts stored under ${COVERAGE_DIR}"

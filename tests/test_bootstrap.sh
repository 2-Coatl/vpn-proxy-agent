#!/bin/bash
# =============================================================================
# VPN/Proxy Agent - Bootstrap Behavior Tests
# =============================================================================
# Description: Focused tests for bootstrap automation helpers
# Usage: ./tests/test_bootstrap.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/validation.sh"
source "${PROJECT_ROOT}/utils/common.sh"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [ "$expected" = "$actual" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "[PASS] $test_name"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "[FAIL] $test_name"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
    fi
}

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------

test_auto_mode_detection() {
    echo ""
    echo "=== Testing bootstrap auto mode detection ==="

    local output
    output=$({
        cd "$PROJECT_ROOT"
        source "./bootstrap.sh"
        if declare -F auto_mode_enabled >/dev/null; then
            BOOTSTRAP_AUTO=1 auto_mode_enabled && echo "enabled" || echo "disabled"
        else
            echo "missing"
        fi
    } | tail -n1)

    assert_equals "enabled" "$output" "auto_mode_enabled respects BOOTSTRAP_AUTO"
}

test_detect_unattended_helper() {
    echo ""
    echo "=== Testing bootstrap unattended detection helper ==="

    local output
    output=$({
        cd "$PROJECT_ROOT"
        source "./bootstrap.sh"
        if declare -F detect_unattended_context >/dev/null; then
            BOOTSTRAP_AUTO=0 CI=0 DEBIAN_FRONTEND=noninteractive detect_unattended_context && echo "auto" || echo "manual"
        else
            echo "missing"
        fi
    } | tail -n1)

    assert_equals "auto" "$output" "detect_unattended_context honors DEBIAN_FRONTEND"

    output=$({
        cd "$PROJECT_ROOT"
        source "./bootstrap.sh"
        if declare -F detect_unattended_context >/dev/null; then
            BOOTSTRAP_AUTO=0 CI=0 DEBIAN_FRONTEND="" detect_unattended_context tty && echo "auto" || echo "manual"
        else
            echo "missing"
        fi
    } | tail -n1)

    assert_equals "manual" "$output" "detect_unattended_context detects interactive fallback"
}

test_auto_install_resolution() {
    echo ""
    echo "=== Testing bootstrap auto install resolution ==="

    local output
    output=$({
        cd "$PROJECT_ROOT"
        source "./bootstrap.sh"
        if declare -F resolve_install_type >/dev/null; then
            BOOTSTRAP_AUTO=1 BOOTSTRAP_INSTALL_TYPE="" resolve_install_type "" || true
        else
            echo "missing"
        fi
    } | tail -n1)

    assert_equals "standard" "$output" "resolve_install_type defaults to standard in auto mode"

    output=$({
        cd "$PROJECT_ROOT"
        source "./bootstrap.sh"
        if declare -F resolve_install_type >/dev/null; then
            BOOTSTRAP_AUTO=1 BOOTSTRAP_INSTALL_TYPE="quick" resolve_install_type "" || true
        else
            echo "missing"
        fi
    } | tail -n1)

    assert_equals "quick" "$output" "resolve_install_type honors BOOTSTRAP_INSTALL_TYPE"

    output=$({
        cd "$PROJECT_ROOT"
        source "./bootstrap.sh"
        if declare -F resolve_install_type >/dev/null; then
            BOOTSTRAP_AUTO=1 BOOTSTRAP_INSTALL_TYPE="COMPLETE" resolve_install_type "" || true
        else
            echo "missing"
        fi
    } | tail -n1)

    assert_equals "complete" "$output" "resolve_install_type normalizes uppercase install type"
}

test_auto_confirmation() {
    echo ""
    echo "=== Testing bootstrap auto confirmation ==="

    local output
    output=$({
        cd "$PROJECT_ROOT"
        source "./bootstrap.sh"
        if declare -F should_auto_confirm >/dev/null; then
            BOOTSTRAP_AUTO=1 should_auto_confirm && echo "yes" || echo "no"
        else
            echo "missing"
        fi
    } | tail -n1)

    assert_equals "yes" "$output" "should_auto_confirm approves when auto mode"

    output=$({
        cd "$PROJECT_ROOT"
        source "./bootstrap.sh"
        if declare -F should_auto_confirm >/dev/null; then
            BOOTSTRAP_AUTO=0 BOOTSTRAP_ASSUME_YES="true" should_auto_confirm && echo "yes" || echo "no"
        else
            echo "missing"
        fi
    } | tail -n1)

    assert_equals "yes" "$output" "should_auto_confirm respects BOOTSTRAP_ASSUME_YES"

    output=$({
        cd "$PROJECT_ROOT"
        source "./bootstrap.sh"
        if declare -F should_auto_confirm >/dev/null; then
            BOOTSTRAP_AUTO=0 CI=0 DEBIAN_FRONTEND=noninteractive should_auto_confirm && echo "yes" || echo "no"
        else
            echo "missing"
        fi
    } | tail -n1)

    assert_equals "yes" "$output" "should_auto_confirm honors unattended environment"
}

test_vagrant_auto_bootstrap() {
    echo ""
    echo "=== Testing Vagrant auto bootstrap provisioning ==="

    local patterns=(
        "BOOTSTRAP_AUTO=1"
        "BOOTSTRAP_ASSUME_YES=1"
        "logs/bootstrap_auto_complete.flag"
        "vagrant provision --provision-with auto-bootstrap"
        "Remove logs/bootstrap_auto_complete.flag"
    )

    local missing=()
    for pattern in "${patterns[@]}"; do
        if ! grep -q "$pattern" "$PROJECT_ROOT/Vagrantfile"; then
            missing+=("$pattern")
        fi
    done

    TESTS_RUN=$((TESTS_RUN + 1))

    if [ ${#missing[@]} -eq 0 ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "[PASS] Vagrant auto bootstrap provisioning"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "[FAIL] Vagrant auto bootstrap provisioning"
        echo "  Missing patterns:"
        for pattern in "${missing[@]}"; do
            echo "    - $pattern"
        done
    fi
}

# Append new test to run sequence
run_all_tests() {
    test_auto_mode_detection
    test_detect_unattended_helper
    test_auto_install_resolution
    test_auto_confirmation
    test_vagrant_auto_bootstrap

    echo ""
    echo "Tests run: $TESTS_RUN"
    echo "Passed:    $TESTS_PASSED"
    echo "Failed:    $TESTS_FAILED"

    if [ "$TESTS_FAILED" -ne 0 ]; then
        exit 1
    fi
}

run_all_tests

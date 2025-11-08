#!/bin/bash
# =============================================================================
# VPN/Proxy Agent - Utility Functions Test Suite
# =============================================================================
# Description: Test all utility functions
# Usage: ./tests/test_utilities.sh
# =============================================================================

set -e

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "${PROJECT_ROOT}/utils/logging.sh"
source "${PROJECT_ROOT}/utils/validation.sh"
source "${PROJECT_ROOT}/utils/common.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# -----------------------------------------------------------------------------
# Test Framework
# -----------------------------------------------------------------------------

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$expected" = "$actual" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "[PASS] $test_name"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "[FAIL] $test_name"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        return 1
    fi
}

assert_true() {
    local command="$1"
    local test_name="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if eval "$command"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "[PASS] $test_name"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "[FAIL] $test_name"
        return 1
    fi
}

assert_false() {
    local command="$1"
    local test_name="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if ! eval "$command"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "[PASS] $test_name"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "[FAIL] $test_name"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Logging Tests
# -----------------------------------------------------------------------------

test_logging() {
    echo ""
    echo "=== Testing Logging Functions ==="
    
    # Test log_info (should not fail)
    assert_true "log_info 'Test message' >/dev/null 2>&1" "log_info function"
    
    # Test log_success
    assert_true "log_success 'Test success' >/dev/null 2>&1" "log_success function"
    
    # Test log_warn
    assert_true "log_warn 'Test warning' >/dev/null 2>&1" "log_warn function"
    
    # Test log_error
    assert_true "log_error 'Test error' >/dev/null 2>&1" "log_error function"
    
    # Test timer functions
    assert_true "start_timer 'test'" "start_timer function"
    assert_true "end_timer 'test' 'Test operation' >/dev/null 2>&1" "end_timer function"
}

# -----------------------------------------------------------------------------
# Validation Tests
# -----------------------------------------------------------------------------

test_validation() {
    echo ""
    echo "=== Testing Validation Functions ==="
    
    # Test command validation
    assert_true "validate_command_exists bash" "validate existing command"
    assert_false "validate_command_exists nonexistent_command_xyz" "validate non-existing command"
    
    # Test Python version format
    assert_true "validate_python_version_format '3.12.6'" "valid Python version format"
    assert_false "validate_python_version_format '3.12'" "invalid Python version format"
    assert_false "validate_python_version_format '3.12.6.1'" "invalid Python version format (too long)"
    
    # Test port validation
    assert_true "validate_port 8080" "valid port number"
    assert_false "validate_port 0" "invalid port (0)"
    assert_false "validate_port 70000" "invalid port (>65535)"
    assert_false "validate_port 'abc'" "invalid port (non-numeric)"
    
    # Test IP validation
    assert_true "validate_ip '192.168.1.1'" "valid IP address"
    assert_true "validate_ip '10.0.0.1'" "valid IP address"
    assert_false "validate_ip '256.1.1.1'" "invalid IP (octet >255)"
    assert_false "validate_ip 'not.an.ip.address'" "invalid IP format"
    
    # Test URL validation
    assert_true "validate_url 'https://example.com'" "valid HTTPS URL"
    assert_true "validate_url 'http://test.com'" "valid HTTP URL"
    assert_false "validate_url 'ftp://test.com'" "invalid URL protocol"
    assert_false "validate_url 'not-a-url'" "invalid URL format"
}

# -----------------------------------------------------------------------------
# Common Utility Tests
# -----------------------------------------------------------------------------

test_common() {
    echo ""
    echo "=== Testing Common Functions ==="
    
    # Test OS detection
    assert_true "detect_os_version" "OS detection"
    
    # Test string utilities
    local test_string="  test  "
    local trimmed=$(trim "$test_string")
    assert_equals "test" "$trimmed" "trim function"
    
    local lowercase=$(to_lowercase "TEST")
    assert_equals "test" "$lowercase" "to_lowercase function"
    
    local uppercase=$(to_uppercase "test")
    assert_equals "TEST" "$uppercase" "to_uppercase function"
    
    local slugified=$(slugify "Test String")
    assert_equals "test_string" "$slugified" "slugify function"
    
    # Test artifact naming
    local artifact=$(get_artifact_name "python" "3.12.6" ".tar.gz")
    assert_equals "python-3.12.6.tar.gz" "$artifact" "get_artifact_name function"
    
    # Test temp directory creation
    local temp_dir=$(create_temp_dir "test")
    assert_true "[ -d '$temp_dir' ]" "create_temp_dir function"
    
    # Test cleanup
    assert_true "cleanup_temp_dir '$temp_dir'" "cleanup_temp_dir function"
    assert_false "[ -d '$temp_dir' ]" "temp directory cleaned up"
}

# -----------------------------------------------------------------------------
# File Operation Tests
# -----------------------------------------------------------------------------

test_file_operations() {
    echo ""
    echo "=== Testing File Operations ==="
    
    # Create test file
    local test_file="/tmp/vpn_proxy_test_file.txt"
    echo "test content" > "$test_file"
    
    # Test file validation
    assert_true "validate_file_exists '$test_file'" "file exists validation"
    assert_true "validate_file_readable '$test_file'" "file readable validation"
    
    # Test backup
    assert_true "backup_file '$test_file' '.test_backup'" "backup_file function"
    assert_true "[ -f '${test_file}.test_backup' ]" "backup file created"
    
    # Cleanup
    rm -f "$test_file" "${test_file}.test_backup"
}

# -----------------------------------------------------------------------------
# Integration Tests
# -----------------------------------------------------------------------------

test_integration() {
    echo ""
    echo "=== Testing Integration Scenarios ==="
    
    # Test complete workflow
    assert_true "detect_os_version && [ -n \"\$OS_ID\" ]" "OS detection sets variables"
    
    # Test validation chain
    local valid_port="8080"
    assert_true "validate_port '$valid_port' && echo 'Port validated' >/dev/null" "validation chain"
}

# -----------------------------------------------------------------------------
# Main Test Runner
# -----------------------------------------------------------------------------

main() {
    echo "=============================================="
    echo "  VPN/Proxy Agent - Utility Test Suite"
    echo "=============================================="
    
    # Run test suites
    test_logging
    test_validation
    test_common
    test_file_operations
    test_integration
    
    # Print summary
    echo ""
    echo "=============================================="
    echo "  Test Results"
    echo "=============================================="
    echo "Tests Run:    $TESTS_RUN"
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo "=============================================="
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo "[SUCCESS] All tests passed!"
        exit 0
    else
        echo "[FAILURE] Some tests failed"
        exit 1
    fi
}

# Run tests
main "$@"

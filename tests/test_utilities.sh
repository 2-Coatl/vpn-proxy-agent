#!/bin/bash
# =============================================================================
# VPN/Proxy Agent - Utility Functions Test Suite
# =============================================================================
# Description: Test all utility functions
# Usage: ./tests/test_utilities.sh
# =============================================================================

set -euo pipefail

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "${LOCAL_PROJECT_ROOT}/utils/logging.sh"
PROJECT_ROOT="$LOCAL_PROJECT_ROOT"
source "${PROJECT_ROOT}/utils/validation.sh"
PROJECT_ROOT="$LOCAL_PROJECT_ROOT"
source "${PROJECT_ROOT}/utils/common.sh"
PROJECT_ROOT="$LOCAL_PROJECT_ROOT"

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

# Verify logging respects environment-provided directories
test_logging_preserves_local_paths() {
    echo ""
    echo "=== Testing Logging Environment Preservation ==="

    local output
    output=$(
        set -euo pipefail
        cd "$LOCAL_PROJECT_ROOT"
        whoami() { echo vagrant; }
        source "utils/env.sh"
        source "utils/logging.sh"
        echo "LOGS_DIR=$LOGS_DIR"
    )

    local expected_logs_dir="${LOCAL_PROJECT_ROOT}/logs"
    local actual_logs_dir
    actual_logs_dir=$(echo "$output" | awk -F'=' '/^LOGS_DIR=/ {print $2}')

    assert_equals "$expected_logs_dir" "$actual_logs_dir" "logging preserves env-defined LOGS_DIR"
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

# Ensure bootstrap selection works without predefined arguments
test_select_install_type_interactive() {
    echo ""
    echo "=== Testing Bootstrap Installation Selection ==="

    local output
    output=$(printf '1\n' | bash -c '
        set -euo pipefail
        cd "'$LOCAL_PROJECT_ROOT'"
        source "./bootstrap.sh"
        select_install_type
    ' | tail -n 1)

    output="${output##*: }"

    assert_equals "quick" "$output" "select_install_type handles interactive input"
}

# -----------------------------------------------------------------------------
# Environment Setup Tests
# -----------------------------------------------------------------------------

test_environment_setup() {
    echo ""
    echo "=== Testing Environment Setup ==="

    local temp_root
    temp_root="$(mktemp -d)"
    local temp_utils_dir="${temp_root}/utils"
    local temp_config_dir="${temp_root}/config"
    mkdir -p "$temp_utils_dir" "$temp_config_dir"

    cp "${PROJECT_ROOT}/utils/env.sh" "${temp_utils_dir}/env.sh"

    local config_file="${temp_config_dir}/versions.conf"
    cat >"$config_file" <<EOF
PROJECT_ROOT="${temp_root}/project"
SCRIPTS_DIR="${temp_root}/scripts"
LOGS_DIR="${temp_root}/logs"
BACKUPS_DIR="${temp_root}/backups"
DATA_DIR="${temp_root}/data"
EOF

    local expected_config_message_path="${temp_utils_dir}/../config/versions.conf"

    local env_output
    env_output=$(
        whoami() { echo ubuntu; }
        source "${temp_utils_dir}/env.sh"
        echo "PROJECT_ROOT=$PROJECT_ROOT"
        echo "SCRIPTS_DIR=$SCRIPTS_DIR"
        echo "LOGS_DIR=$LOGS_DIR"
        echo "BACKUPS_DIR=$BACKUPS_DIR"
        echo "DATA_DIR=$DATA_DIR"
    )

    local project_root
    project_root=$(echo "$env_output" | awk -F'=' '/^PROJECT_ROOT=/ {print $2}')
    local scripts_dir
    scripts_dir=$(echo "$env_output" | awk -F'=' '/^SCRIPTS_DIR=/ {print $2}')
    local logs_dir
    logs_dir=$(echo "$env_output" | awk -F'=' '/^LOGS_DIR=/ {print $2}')
    local backups_dir
    backups_dir=$(echo "$env_output" | awk -F'=' '/^BACKUPS_DIR=/ {print $2}')
    local data_dir
    data_dir=$(echo "$env_output" | awk -F'=' '/^DATA_DIR=/ {print $2}')

    assert_true "echo \"$env_output\" | grep -q 'Configuración cargada desde $expected_config_message_path'" "env.sh informs config load"
    assert_equals "${temp_root}/project" "$project_root" "env.sh sets PROJECT_ROOT from config"
    assert_equals "${temp_root}/scripts" "$scripts_dir" "env.sh sets SCRIPTS_DIR from config"
    assert_equals "${temp_root}/logs" "$logs_dir" "env.sh sets LOGS_DIR from config"
    assert_equals "${temp_root}/backups" "$backups_dir" "env.sh sets BACKUPS_DIR from config"
    assert_equals "${temp_root}/data" "$data_dir" "env.sh sets DATA_DIR from config"

    assert_true "[ -d '${temp_root}/logs' ]" "env.sh ensures LOGS_DIR exists"
    assert_true "[ -d '${temp_root}/backups' ]" "env.sh ensures BACKUPS_DIR exists"
    assert_true "[ -d '${temp_root}/data' ]" "env.sh ensures DATA_DIR exists"

    rm -rf "$temp_root"
}

test_env_fallback_for_non_ubuntu_users() {
    echo ""
    echo "=== Testing Environment Fallback for Non-Ubuntu Users ==="

    local temp_root
    temp_root="$(mktemp -d)"
    local temp_utils_dir="${temp_root}/utils"
    local temp_config_dir="${temp_root}/config"
    mkdir -p "$temp_utils_dir" "$temp_config_dir"

    cp "${PROJECT_ROOT}/utils/env.sh" "${temp_utils_dir}/env.sh"

    cat >"${temp_config_dir}/versions.conf" <<'EOF'
: "${PROJECT_ROOT:=/home/ubuntu/projects}"
: "${SCRIPTS_DIR:=/home/ubuntu/scripts}"
: "${LOGS_DIR:=/home/ubuntu/logs}"
: "${BACKUPS_DIR:=/home/ubuntu/backups}"
: "${DATA_DIR:=/srv/data}"
EOF

    local env_output
    env_output=$(cd "$temp_root" && (
        set -euo pipefail
        whoami() { echo vagrant; }
        source "utils/env.sh"
        echo "PROJECT_ROOT=$PROJECT_ROOT"
        echo "SCRIPTS_DIR=$SCRIPTS_DIR"
        echo "LOGS_DIR=$LOGS_DIR"
        echo "BACKUPS_DIR=$BACKUPS_DIR"
        echo "DATA_DIR=$DATA_DIR"
    ))

    local project_root
    project_root=$(echo "$env_output" | awk -F'=' '/^PROJECT_ROOT=/ {print $2}')
    local scripts_dir
    scripts_dir=$(echo "$env_output" | awk -F'=' '/^SCRIPTS_DIR=/ {print $2}')
    local logs_dir
    logs_dir=$(echo "$env_output" | awk -F'=' '/^LOGS_DIR=/ {print $2}')
    local backups_dir
    backups_dir=$(echo "$env_output" | awk -F'=' '/^BACKUPS_DIR=/ {print $2}')
    local data_dir
    data_dir=$(echo "$env_output" | awk -F'=' '/^DATA_DIR=/ {print $2}')

    assert_equals "$temp_root" "$project_root" "env.sh maps PROJECT_ROOT to repository root for non-ubuntu"
    assert_equals "${temp_root}/scripts" "$scripts_dir" "env.sh maps SCRIPTS_DIR to repository scripts directory"
    assert_equals "${temp_root}/logs" "$logs_dir" "env.sh maps LOGS_DIR to repository logs directory"
    assert_equals "${temp_root}/backups" "$backups_dir" "env.sh maps BACKUPS_DIR to repository backups directory"
    assert_equals "${temp_root}/data" "$data_dir" "env.sh maps DATA_DIR to repository data directory"

    assert_true "[ -d '${temp_root}/logs' ]" "env.sh creates logs directory for non-ubuntu"
    assert_true "[ -d '${temp_root}/backups' ]" "env.sh creates backups directory for non-ubuntu"
    assert_true "[ -d '${temp_root}/data' ]" "env.sh creates data directory for non-ubuntu"

    rm -rf "$temp_root"
}

test_env_recovers_scripts_dir_when_required_scripts_missing() {
    echo ""
    echo "=== Testing Environment Scripts Directory Recovery ==="

    local temp_root
    temp_root="$(mktemp -d)"
    local temp_utils_dir="${temp_root}/utils"
    local temp_config_dir="${temp_root}/config"
    local temp_scripts_dir="${temp_root}/scripts"

    mkdir -p "$temp_utils_dir" "$temp_config_dir" "$temp_scripts_dir"

    cp "${PROJECT_ROOT}/utils/env.sh" "${temp_utils_dir}/env.sh"

    cat >"${temp_config_dir}/versions.conf" <<'EOF'
: "${PROJECT_ROOT:=/home/ubuntu/projects}"
: "${SCRIPTS_DIR:=/home/ubuntu/scripts}"
: "${LOGS_DIR:=/home/ubuntu/logs}"
: "${BACKUPS_DIR:=/home/ubuntu/backups}"
: "${DATA_DIR:=/srv/data}"
EOF

    touch "${temp_scripts_dir}/setup_ssh.sh"

    local env_output
    env_output=$(cd "$temp_root" && (
        set -euo pipefail
        whoami() { echo ubuntu; }
        SCRIPTS_DIR="${temp_utils_dir}/scripts"
        export SCRIPTS_DIR
        source "utils/env.sh"
        echo "SCRIPTS_DIR=$SCRIPTS_DIR"
    ))

    local scripts_dir
    scripts_dir=$(echo "$env_output" | awk -F'=' '/^SCRIPTS_DIR=/ {print $2}')

    assert_equals "${temp_scripts_dir}" "$scripts_dir" "env.sh resets SCRIPTS_DIR to repository scripts when required scripts missing"

    rm -rf "$temp_root"
}

# -----------------------------------------------------------------------------
# Script Sourcing Tests
# -----------------------------------------------------------------------------

test_env_sourcing_alignment() {
    echo ""
    echo "=== Testing Environment Sourcing Alignment ==="

    local scripts_to_check=(
        "bootstrap.sh"
        "installer/install.sh"
        "scripts/backup_daily.sh"
        "scripts/backup_system.sh"
        "scripts/dashboard.sh"
        "scripts/diagnose_all.sh"
        "scripts/feature_install.sh"
        "scripts/master_setup.sh"
        "scripts/restart_services.sh"
        "scripts/safe_update.sh"
        "scripts/setup_docker.sh"
        "scripts/setup_ssh.sh"
        "scripts/setup_tunnel.sh"
        "scripts/setup_wireguard.sh"
        "scripts/validate_build.sh"
        "scripts/validate_wrapper.sh"
        "scripts/watchdog_tunnel.sh"
    )

    declare -A requires_env=(
        ["bootstrap.sh"]=1
        ["scripts/backup_daily.sh"]=1
        ["scripts/backup_system.sh"]=1
        ["scripts/master_setup.sh"]=1
        ["scripts/restart_services.sh"]=1
        ["scripts/safe_update.sh"]=1
        ["scripts/watchdog_tunnel.sh"]=1
    )

    for script_path in "${scripts_to_check[@]}"; do
        local full_path="${PROJECT_ROOT}/${script_path}"
        assert_true "[ -f '$full_path' ]" "${script_path} exists"

        if [[ -n "${requires_env[$script_path]:-}" ]]; then
            assert_true "grep -E 'source .*env\\.sh' '$full_path' >/dev/null" "${script_path} sources env.sh"
        else
            assert_false "grep -E 'source .*env\\.sh' '$full_path' >/dev/null" "${script_path} avoids unnecessary env.sh sourcing"
        fi
    done
}

test_env_preserves_script_context() {
    echo ""
    echo "=== Testing env.sh Preserves Caller Context ==="

    local temp_root
    temp_root="$(mktemp -d)"
    local temp_utils_dir="${temp_root}/utils"
    local temp_config_dir="${temp_root}/config"
    mkdir -p "$temp_utils_dir" "$temp_config_dir"

    cp "${PROJECT_ROOT}/utils/env.sh" "${temp_utils_dir}/env.sh"

    cat >"${temp_config_dir}/versions.conf" <<EOF
PROJECT_ROOT="${temp_root}/project"
SCRIPTS_DIR="${temp_root}/scripts"
LOGS_DIR="${temp_root}/logs"
BACKUPS_DIR="${temp_root}/backups"
DATA_DIR="${temp_root}/data"
EOF

    local result
    result=$(
        whoami() { echo ubuntu; }
        SCRIPT_PATH="/tmp/caller_script.sh"
        SCRIPT_DIR="/tmp/caller_dir"
        source "${temp_utils_dir}/env.sh"
        echo "SCRIPT_PATH=$SCRIPT_PATH"
        echo "SCRIPT_DIR=$SCRIPT_DIR"
    )

    assert_equals "SCRIPT_PATH=/tmp/caller_script.sh" "$(echo "$result" | awk -F'=' '/^SCRIPT_PATH=/ {print $0}')" "env.sh preserves SCRIPT_PATH"
    assert_equals "SCRIPT_DIR=/tmp/caller_dir" "$(echo "$result" | awk -F'=' '/^SCRIPT_DIR=/ {print $0}')" "env.sh preserves SCRIPT_DIR"

    rm -rf "$temp_root"
}

# -----------------------------------------------------------------------------
# Script Safety Tests
# -----------------------------------------------------------------------------

test_scripts_enforce_strict_mode() {
    echo ""
    echo "=== Testing Script Error Handling Strictness ==="

    local scripts_to_validate=(
        "bootstrap.sh"
        "installer/install.sh"
        "scripts/backup_daily.sh"
        "scripts/backup_system.sh"
        "scripts/build_cpython.sh"
        "scripts/build_wrapper.sh"
        "scripts/dashboard.sh"
        "scripts/diagnose_all.sh"
        "scripts/feature_install.sh"
        "scripts/health_check.sh"
        "scripts/master_setup.sh"
        "scripts/restart_services.sh"
        "scripts/safe_update.sh"
        "scripts/setup_docker.sh"
        "scripts/setup_ssh.sh"
        "scripts/setup_tunnel.sh"
        "scripts/setup_wireguard.sh"
        "scripts/validate_build.sh"
        "scripts/validate_wrapper.sh"
        "scripts/watchdog_tunnel.sh"
        "tests/test_utilities.sh"
    )

    for script in "${scripts_to_validate[@]}"; do
        local script_path="${PROJECT_ROOT}/${script}"
        assert_true "[ -f '$script_path' ]" "${script} exists"
        assert_true "grep -E '^set -euo pipefail$' '$script_path' >/dev/null" "${script} enforces strict error handling"
    done
}

# -----------------------------------------------------------------------------
# Bootstrap Integration Tests
# -----------------------------------------------------------------------------

test_bootstrap_delegates_to_specialized_scripts() {
    echo ""
    echo "=== Testing Bootstrap Delegation to Specialized Scripts ==="

    local bootstrap_path="${PROJECT_ROOT}/bootstrap.sh"

    assert_true "[ -f '$bootstrap_path' ]" "bootstrap.sh exists"
    assert_true \
        "grep -E 'bash \"\\$\\{SCRIPTS_DIR\\}/setup_ssh\\.sh\"' '$bootstrap_path' >/dev/null" \
        "bootstrap.sh delegates SSH setup to setup_ssh.sh"
    assert_true \
        "grep -E 'backup_daily\\.sh' '$bootstrap_path' >/dev/null" \
        "bootstrap.sh references backup_daily.sh"
    assert_true \
        "grep -E '/etc/cron\.d/vpn_proxy_backups' '$bootstrap_path' >/dev/null" \
        "bootstrap.sh provisions cron configuration for backups"
    assert_true \
        "grep -E 'bash \"\\$\\{SCRIPTS_DIR\\}/setup_wireguard\\.sh\"' '$bootstrap_path' >/dev/null" \
        "bootstrap.sh delegates WireGuard setup to setup_wireguard.sh"
}

test_bootstrap_automation_flow() {
    echo ""
    echo "=== Testing Bootstrap Automation Flow ==="

    local output
    output=$(cd "$LOCAL_PROJECT_ROOT" && BOOTSTRAP_AUTO=1 BOOTSTRAP_INSTALL_TYPE="COMPLETE" BOOTSTRAP_ASSUME_YES=1 bash -c '
        set -euo pipefail

        source "./bootstrap.sh"

        start_timer() { echo "START_TIMER:$1"; }
        end_timer() { echo "END_TIMER:$1"; echo "3s"; }
        show_welcome() { echo "WELCOME"; }
        check_requirements() { echo "CHECK_REQ"; return 0; }
        detect_os_version() { OS_PRETTY_NAME="Ubuntu Test"; return 0; }
        show_install_summary() { echo "SUMMARY:$1"; }
        do_quick_install() { echo "DO_QUICK"; return 0; }
        do_standard_install() { echo "DO_STANDARD"; return 0; }
        do_complete_install() { echo "DO_COMPLETE"; return 0; }
        show_completion() { echo "COMPLETE:$1:$2"; }
        log_info() { echo "INFO:$*"; }
        log_warn() { echo "WARN:$*"; }
        log_error() { echo "ERROR:$*"; }
        log_success() { echo "SUCCESS:$*"; }
        log_box() { echo "BOX:$*"; }
        log_header() { echo "HEADER:$*"; }
        log_step() { echo "STEP:$*"; }
        log_summary_start() { echo "SUMMARY_START"; }
        log_summary_item() { echo "SUMMARY_ITEM:$1=$2"; }
        log_summary_end() { echo "SUMMARY_END"; }
        log_confirm() { echo "CONFIRM:$1"; return 0; }

        LOG_FILE="$(mktemp)"

        main
    ' 2>&1)

    assert_true "echo \"$output\" | grep -q 'INFO:Automation mode detected'" "bootstrap main reports automation mode"
    assert_true "echo \"$output\" | grep -q 'DO_COMPLETE'" "bootstrap selects complete install under automation"
    assert_true "echo \"$output\" | grep -q 'INFO:Auto-confirmation enabled'" "bootstrap skips confirmation under automation"
    assert_false "echo \"$output\" | grep -q 'CONFIRM:'" "bootstrap does not prompt when auto confirm active"
}

# -----------------------------------------------------------------------------
# Build Automation Tests
# -----------------------------------------------------------------------------

test_makefile_targets() {
    echo ""
    echo "=== Testing Makefile Targets ==="

    local makefile_path="${PROJECT_ROOT}/Makefile"

    assert_true "[ -f '$makefile_path' ]" "Makefile exists"
    assert_true "grep -E '^help:' '$makefile_path' >/dev/null" "help target defined"
    assert_true "grep -E '^test:' '$makefile_path' >/dev/null" "test target defined"
    assert_true "grep -E '^test-python:' '$makefile_path' >/dev/null" "test-python target defined"
    assert_true "grep -E '^docs-serve:' '$makefile_path' >/dev/null" "docs-serve target defined"
    assert_true "grep -E '^docs-build:' '$makefile_path' >/dev/null" "docs-build target defined"

    assert_true "make -C '$PROJECT_ROOT' -n help >/dev/null" "make help succeeds"
}

# -----------------------------------------------------------------------------
# Documentation Tests
# -----------------------------------------------------------------------------

test_docs_site_content() {
    echo ""
    echo "=== Testing Documentation Assets ==="

    local docs_dir="${PROJECT_ROOT}/docs"
    local mkdocs_config="${PROJECT_ROOT}/docs/mkdocs.yml"
    local index_page="${docs_dir}/index.md"
    local about_page="${docs_dir}/about.md"
    local tutorial_page="${docs_dir}/mkdocs_tutorial.md"
    local img_placeholder="${docs_dir}/img/.gitkeep"
    local pr_workflow_page="${docs_dir}/pr_workflow.md"

    assert_true "[ -d '$docs_dir' ]" "docs directory exists"
    assert_true "[ -f '$mkdocs_config' ]" "mkdocs.yml exists"
    assert_true "[ -f '$index_page' ]" "index.md exists"
    assert_true "[ -f '$about_page' ]" "about.md exists"
    assert_true "[ -f '$tutorial_page' ]" "mkdocs_tutorial.md exists"
    assert_true "[ -f '$pr_workflow_page' ]" "pr_workflow.md exists"
    assert_true "[ -f '$img_placeholder' ]" "docs/img/.gitkeep exists"

    assert_true "grep -E '^# VPN Proxy Agent Knowledge Base' '$index_page' >/dev/null" "index.md has site heading"
    assert_true "grep -E '^## Quick Start' '$index_page' >/dev/null" "index.md documents quick start"
    assert_true "grep -E '^# Repository Overview' '$about_page' >/dev/null" "about.md has overview heading"
    assert_true "grep -E '^## Current Inventory' '$about_page' >/dev/null" "about.md lists inventory"
    assert_true "grep -E '^# MkDocs Tutorial for VPN Proxy Agent' '$tutorial_page' >/dev/null" "tutorial page heading present"
    assert_true "grep -E '^# PR Workflow Guidance' '$pr_workflow_page' >/dev/null" "pr_workflow.md has heading"
    assert_true "grep -E 'Codex no permite actualizar' '$pr_workflow_page' >/dev/null" "pr_workflow.md explains Codex update limitation"

    assert_true "grep -E '^site_name: ' '$mkdocs_config' >/dev/null" "mkdocs.yml defines site_name"
    assert_true "grep -E 'Home: index\\.md' '$mkdocs_config' >/dev/null" "navigation includes Home"
    assert_true "grep -E 'Repository Overview: about\\.md' '$mkdocs_config' >/dev/null" "navigation includes Repository Overview"
    assert_true "grep -E 'MkDocs Tutorial: mkdocs_tutorial\\.md' '$mkdocs_config' >/dev/null" "navigation includes MkDocs Tutorial"
    assert_true "grep -E 'PR Workflow Guidance: pr_workflow\\.md' '$mkdocs_config' >/dev/null" "navigation includes PR workflow guidance"
    assert_true "grep -E 'name: (material|readthedocs)' '$mkdocs_config' >/dev/null" "mkdocs theme configured"
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
    test_logging_preserves_local_paths
    test_validation
    test_common
    test_select_install_type_interactive
    test_environment_setup
    test_env_fallback_for_non_ubuntu_users
    test_env_recovers_scripts_dir_when_required_scripts_missing
    test_env_sourcing_alignment
    test_env_preserves_script_context
    test_scripts_enforce_strict_mode
    test_bootstrap_delegates_to_specialized_scripts
    test_bootstrap_automation_flow
    test_docs_site_content
    test_makefile_targets
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

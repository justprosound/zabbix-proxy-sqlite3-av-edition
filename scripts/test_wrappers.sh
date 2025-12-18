#!/bin/bash
set -u

# Test wrapper scripts for security and functionality

# Use /dev/null for logging during tests to avoid permission issues
export PASS_TO_SHELL_LOGFILE="/dev/null"

echo "Testing pass-to-shell.sh..."
PASS_TO_SHELL="./scripts/pass-to-shell.sh"

# Mock date command if not available (should be standard, but just in case)
if ! command -v date >/dev/null; then
    echo "Warning: date command not found"
fi

# Function to assert failure (blocked command)
assert_blocked() {
    local cmd="$1"
    if $PASS_TO_SHELL "$cmd" >/dev/null 2>&1; then
        echo "FAIL: Blocked command was allowed: '$cmd'"
        exit 1
    else
        echo "PASS: Blocked command was rejected: '$cmd'"
    fi
}

# Function to assert success (allowed command)
assert_allowed() {
    local cmd="$1"
    if ! output=$($PASS_TO_SHELL "$cmd" 2>&1); then
        echo "FAIL: Allowed command failed: '$cmd'"
        echo "Output: $output"
        exit 1
    else
        echo "PASS: Allowed command succeeded: '$cmd'"
    fi
}

# Test blocked commands
assert_blocked "rm -rf /"
assert_blocked "rm  -rf /" # Extra space
assert_blocked "  rm -rf /" # Leading space
assert_blocked "sudo ls"
assert_blocked "chmod 777 file"
assert_blocked "chmod  777 file"
assert_blocked "cat /etc/passwd" # passwd keyword

# Test allowed commands
assert_allowed "ls -la"
assert_allowed "echo 'hello world'"
assert_allowed "whoami"

echo "All tests passed!"

#!/bin/bash
# test_validate.sh - Unit tests for validate.sh shared validation module
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the validate module
# shellcheck source=validate.sh
source "${SCRIPT_DIR}/validate.sh"

PASS=0
FAIL=0

assert_pass() {
    local desc="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

assert_fail() {
    local desc="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "FAIL: $desc (expected failure but succeeded)"
        FAIL=$((FAIL + 1))
    else
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    fi
}

echo "=== validate_command_length ==="
assert_pass "short command accepted" validate_command_length "ls -la"
assert_pass "exact max length accepted" validate_command_length "$(printf 'a%.0s' {1..1024})"
assert_fail "too-long command rejected" validate_command_length "$(printf 'a%.0s' {1..1025})"

echo ""
echo "=== validate_message_length ==="
assert_pass "short message accepted" validate_message_length "hello"
assert_pass "exact max length accepted" validate_message_length "$(printf 'a%.0s' {1..4096})"
assert_fail "too-long message rejected" validate_message_length "$(printf 'a%.0s' {1..4097})"

echo ""
echo "=== validate_hostname ==="
assert_pass "valid hostname accepted" validate_hostname "zabbix-server.example.com"
assert_pass "valid IP accepted" validate_hostname "192.168.1.100"
assert_fail "empty hostname rejected" validate_hostname ""

echo ""
echo "=== validate_port ==="
assert_pass "port 80 accepted" validate_port "80"
assert_pass "port 10051 accepted" validate_port "10051"
assert_pass "port 65535 accepted" validate_port "65535"
assert_fail "port 0 rejected" validate_port "0"
assert_fail "port 65536 rejected" validate_port "65536"
assert_fail "non-numeric port rejected" validate_port "abc"

echo ""
echo "=== validate_command_safety ==="
assert_pass "safe command 'ls' accepted" validate_command_safety "ls -la"
assert_fail "rm -rf blocked" validate_command_safety "rm -rf /"
assert_fail "sudo blocked" validate_command_safety "sudo ls"
assert_fail "chmod 777 blocked" validate_command_safety "chmod 777 file"
assert_fail "dd if= blocked" validate_command_safety "dd if=/dev/sda of=/dev/null"
assert_fail "mkfs blocked" validate_command_safety "mkfs.ext4 /dev/sda1"
assert_fail "passwd keyword blocked" validate_command_safety "cat /etc/passwd"

echo ""
echo "=== validate_kubectl_operation ==="
assert_pass "kubectl get allowed" validate_kubectl_operation "get"
assert_pass "kubectl describe allowed" validate_kubectl_operation "describe"
assert_pass "kubectl logs allowed" validate_kubectl_operation "logs"
assert_fail "kubectl delete blocked" validate_kubectl_operation "delete"
assert_fail "kubectl exec blocked" validate_kubectl_operation "exec"
assert_fail "kubectl apply blocked" validate_kubectl_operation "apply"
assert_fail "kubectl unknown-op blocked" validate_kubectl_operation "rollback"

echo ""
echo "=== validate_tool_exists ==="
assert_pass "bash exists" validate_tool_exists "bash"
assert_fail "nonexistent tool rejected" validate_tool_exists "nonexistent_tool_xyz_12345"

echo ""
echo "=== Results ==="
TOTAL=$((PASS + FAIL))
echo "Passed: $PASS / $TOTAL"
if [[ $FAIL -gt 0 ]]; then
    echo "FAILED: $FAIL test(s)"
    exit 1
fi
echo "All tests passed!"

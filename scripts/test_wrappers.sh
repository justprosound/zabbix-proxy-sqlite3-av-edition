#!/bin/bash
set -u

# Test wrapper scripts for security and functionality

echo "Testing wrapper scripts..."

# Test k.sh if it exists
if [[ -f "./k.sh" ]]; then
    echo "Testing k.sh..."
    # Basic existence test - k.sh requires kubectl and kubeconfig to fully test
    if [[ -x "./k.sh" ]]; then
        echo "PASS: k.sh exists and is executable"
    else
        echo "FAIL: k.sh missing or not executable"
        exit 1
    fi
else
    echo "INFO: k.sh not found - skipping test"
fi

# Test tcp-req.sh if it exists
if [[ -f "./tcp-req.sh" ]]; then
    echo "Testing tcp-req.sh..."
    # Basic existence test
    if [[ -x "./tcp-req.sh" ]]; then
        echo "PASS: tcp-req.sh exists and is executable"
    else
        echo "FAIL: tcp-req.sh missing or not executable"
        exit 1
    fi
else
    echo "INFO: tcp-req.sh not found - skipping test"
fi

echo "All available tests passed!"


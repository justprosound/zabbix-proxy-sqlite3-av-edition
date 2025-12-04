#!/bin/bash
set -euo pipefail

# Script to detect Zabbix versions from the API
# Usage: ./detect-version.sh [min_version]

MIN_VERSION="${1:-7.0.0}"
# Fetch versions from Zabbix Git repository tags
# This is more reliable than an undocumented API
VERSIONS_RAW=$(git ls-remote --tags --refs https://github.com/zabbix/zabbix.git | cut -d/ -f3 | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V)

if [[ -z "$VERSIONS_RAW" ]]; then
    echo "Error: Failed to fetch versions from Zabbix Git repository" >&2
    exit 1
fi

# Filter versions >= MIN_VERSION and output as JSON array
FILTERED_VERSIONS=$(echo "$VERSIONS_RAW" | awk -v min="$MIN_VERSION" '$0 >= min' | jq -R . | jq -s -c .)

echo "Detected versions: $FILTERED_VERSIONS"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "versions=$FILTERED_VERSIONS" >> "$GITHUB_OUTPUT"
fi

#!/bin/bash
set -euo pipefail

# Script to detect Zabbix versions from the API
# Usage: ./detect-version.sh [min_version]

MIN_VERSION="${1:-7.0.0}"
API_URL="https://api.zabbix.com/v1/reference/versions"

echo "Fetching Zabbix versions >= $MIN_VERSION..."

# Fetch versions from Zabbix API
# We use curl to fetch and jq to filter
VERSIONS_JSON=$(curl -s "$API_URL")

if [[ -z "$VERSIONS_JSON" ]]; then
    echo "Error: Failed to fetch versions from Zabbix API" >&2
    exit 1
fi

# Filter versions:
# 1. Select entries where 'release' is true (stable versions)
# 2. Select entries where version number >= MIN_VERSION
# 3. Sort by version number
# 4. Output as JSON array of version strings
FILTERED_VERSIONS=$(echo "$VERSIONS_JSON" | jq -c --arg min_ver "$MIN_VERSION" '
    [
        .[]
        | select(.release == true)
        | select(.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
        | select(.version >= $min_ver)
        | .version
    ] | sort | unique
')

echo "Detected versions: $FILTERED_VERSIONS"
echo "versions=$FILTERED_VERSIONS" >> "$GITHUB_OUTPUT"

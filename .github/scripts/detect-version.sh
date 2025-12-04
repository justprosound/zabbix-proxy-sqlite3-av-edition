#!/bin/bash
set -euo pipefail

# Script to detect Zabbix versions from the official API
# Usage: ./detect-version.sh [min_version]

MIN_VERSION="${1:-7.0.0}"
API_URL="https://services.zabbix.com/updates/v1"

echo "Fetching Zabbix versions >= $MIN_VERSION..."

# Fetch versions from Zabbix API
VERSIONS_JSON=$(curl -sf "$API_URL")

if [[ -z "$VERSIONS_JSON" ]]; then
    echo "Error: Failed to fetch versions from Zabbix API" >&2
    exit 1
fi

# Extract major.minor from MIN_VERSION for comparison
MIN_MAJOR_MINOR=$(echo "$MIN_VERSION" | cut -d. -f1-2)

# Filter versions:
# 1. Select versions where major.minor >= MIN_MAJOR_MINOR
# 2. Extract the latest_release.release field (e.g., "7.0.21")
# 3. Output as JSON array
FILTERED_VERSIONS=$(echo "$VERSIONS_JSON" | jq -c --arg min_mm "$MIN_MAJOR_MINOR" '
    [
        .versions[]
        | select(.version >= $min_mm)
        | .latest_release.release
    ] | sort
')

echo "Detected versions: $FILTERED_VERSIONS"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "versions=$FILTERED_VERSIONS" >> "$GITHUB_OUTPUT"
fi

#!/bin/bash
set -euo pipefail

# Script to detect Zabbix versions from the official API and git tags
# Usage: ./detect-version.sh [min_version]
#
# Strategy:
# 1. Use official Zabbix API to get supported major.minor series
# 2. Use git ls-remote to get all patch versions for those series

MIN_VERSION="${1:-7.0.0}"
API_URL="https://services.zabbix.com/updates/v1"
ZABBIX_REPO="https://github.com/zabbix/zabbix.git"

echo "Fetching supported Zabbix versions >= $MIN_VERSION..."

# Extract major.minor from MIN_VERSION for comparison
MIN_MAJOR_MINOR=$(echo "$MIN_VERSION" | cut -d. -f1-2)

# Step 1: Get supported series from Zabbix API
echo "Querying Zabbix API for supported series..."
VERSIONS_JSON=$(curl -sf "$API_URL") || {
    echo "Warning: Failed to fetch from Zabbix API, falling back to git only" >&2
    VERSIONS_JSON=""
}

if [[ -n "$VERSIONS_JSON" ]]; then
    # Extract supported major.minor series from API
    SUPPORTED_SERIES=$(echo "$VERSIONS_JSON" | jq -r --arg min_mm "$MIN_MAJOR_MINOR" '
        .versions[]
        | select(.version >= $min_mm)
        | .version
    ')
    echo "Supported series from API: $SUPPORTED_SERIES"
else
    # Fallback: use MIN_VERSION as the only filter
    SUPPORTED_SERIES=""
fi

# Step 2: Get all tags from Zabbix git repository
echo "Fetching all tags from Zabbix repository..."
ALL_TAGS=$(git ls-remote --tags --refs "$ZABBIX_REPO" | cut -d/ -f3 | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V)

if [[ -z "$ALL_TAGS" ]]; then
    echo "Error: Failed to fetch tags from Zabbix Git repository" >&2
    exit 1
fi

# Step 3: Filter tags to only include versions from supported series
if [[ -n "$SUPPORTED_SERIES" ]]; then
    # Build a regex pattern from supported series (e.g., "^7\.0\.|^7\.2\.|^7\.4\.")
    SERIES_PATTERN=$(echo "$SUPPORTED_SERIES" | sed 's/\./\\./g' | sed 's/^/^/' | sed 's/$/./' | tr '\n' '|' | sed 's/|$//')
    FILTERED_VERSIONS=$(echo "$ALL_TAGS" | grep -E "$SERIES_PATTERN" | awk -v min="$MIN_VERSION" '$0 >= min')
else
    # No API data, just filter by MIN_VERSION
    FILTERED_VERSIONS=$(echo "$ALL_TAGS" | awk -v min="$MIN_VERSION" '$0 >= min')
fi

# Convert to JSON array
VERSIONS_ARRAY=$(echo "$FILTERED_VERSIONS" | jq -R . | jq -s -c .)

echo "Detected versions: $VERSIONS_ARRAY"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "versions=$VERSIONS_ARRAY" >> "$GITHUB_OUTPUT"
fi

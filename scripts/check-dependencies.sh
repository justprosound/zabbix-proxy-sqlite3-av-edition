#!/bin/bash
# check-dependencies.sh - Unified dependency version checker
# Reads versions.json manifest and checks for updates
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
VERSIONS_JSON="${REPO_ROOT}/versions.json"

# Check dependencies
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required" >&2
    exit 1
fi

if [[ ! -f "$VERSIONS_JSON" ]]; then
    echo "Error: versions manifest not found at $VERSIONS_JSON" >&2
    exit 1
fi

JSON_OUTPUT=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --json) JSON_OUTPUT=true; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Results tracking
UPDATES_FOUND=0
CHECKS_RUN=0
RESULTS="[]"

# Helper: extract current version from source
get_current_version() {
    local tool_name="$1"
    local type pattern file
    
    type=$(jq -r --arg name "$tool_name" '.tools[] | select(.name == $name) | .current_source.type' "$VERSIONS_JSON")
    file=$(jq -r --arg name "$tool_name" '.tools[] | select(.name == $name) | .current_source.file' "$VERSIONS_JSON")
    pattern=$(jq -r --arg name "$tool_name" '.tools[] | select(.name == $name) | .current_source.pattern' "$VERSIONS_JSON")
    
    if [[ "$type" == "regex" ]]; then
        grep -oP "$pattern" "${REPO_ROOT}/${file}" 2>/dev/null | head -1 | sed "s/.*=//"
    else
        echo ""
    fi
}

# Helper: check latest version via Zabbix API
check_zabbix_api() {
    local api_url="$1"
    local current_version="$2"
    
    # Extract major.minor
    local major_minor
    major_minor=$(echo "$current_version" | grep -oP '^[0-9]+\.[0-9]+')
    
    # Fetch API data
    local api_data
    if ! api_data=$(curl -s -f -S "$api_url" 2>/dev/null); then
        echo "::error::Failed to fetch Zabbix versions from API"
        echo "$current_version"
        return
    fi
    
    # Get latest version for current major.minor
    local latest_version
    latest_version=$(echo "$api_data" | jq -r ".versions[] | select(.version == \"$major_minor\") | .latest_release.release")
    
    if [[ -z "$latest_version" ]]; then
        echo "$current_version"
    else
        echo "$latest_version"
    fi
}

# Helper: check latest version via web scrape
check_web_scrape() {
    local url="$1"
    local extract_pattern="$2"
    
    local page
    if ! page=$(curl -s "$url" 2>/dev/null); then
        echo ""
        return
    fi
    
    echo "$page" | grep -oP "$extract_pattern" | sort -V | tail -n1 | sed 's/.*-//;s/-linux.*//'
}

# Helper: check latest version via PyPI
check_pypi() {
    local package="$1"
    
    pip index versions "$package" 2>/dev/null | grep -oP 'Available versions: \K.*' | tr ',' ' ' | awk '{print $NF}'
}

# Helper: check latest version via Kubernetes release
check_kubernetes_release() {
    local stable_url="$1"
    
    curl -Ls "$stable_url" 2>/dev/null
}

# Main check loop
check_tool() {
    local tool_name="$1"
    local display_name
    local check_type
    local current_version
    local latest_version
    local has_update="false"
    local update_action
    
    display_name=$(jq -r --arg name "$tool_name" '.tools[] | select(.name == $name) | .display_name' "$VERSIONS_JSON")
    check_type=$(jq -r --arg name "$tool_name" '.tools[] | select(.name == $name) | .check_method.type' "$VERSIONS_JSON")
    update_action=$(jq -r --arg name "$tool_name" '.tools[] | select(.name == $name) | .update_action' "$VERSIONS_JSON")
    
    echo "Checking $display_name..."
    
    # Get current version
    current_version=$(get_current_version "$tool_name")
    if [[ -z "$current_version" ]]; then
        echo "::warning::Could not extract current $display_name version"
        return
    fi
    
    # Check latest version
    case "$check_type" in
        zabbix_api)
            local api_url
            api_url=$(jq -r --arg name "$tool_name" '.tools[] | select(.name == $name) | .check_method.api_url' "$VERSIONS_JSON")
            latest_version=$(check_zabbix_api "$api_url" "$current_version")
            ;;
        web_scrape)
            local url pattern
            url=$(jq -r --arg name "$tool_name" '.tools[] | select(.name == $name) | .check_method.url' "$VERSIONS_JSON")
            pattern=$(jq -r --arg name "$tool_name" '.tools[] | select(.name == $name) | .check_method.extract_pattern' "$VERSIONS_JSON")
            latest_version=$(check_web_scrape "$url" "$pattern")
            ;;
        pypi)
            local package
            package=$(jq -r --arg name "$tool_name" '.tools[] | select(.name == $name) | .check_method.package' "$VERSIONS_JSON")
            latest_version=$(check_pypi "$package")
            ;;
        kubernetes_release)
            local stable_url
            stable_url=$(jq -r --arg name "$tool_name" '.tools[] | select(.name == $name) | .check_method.stable_url' "$VERSIONS_JSON")
            latest_version=$(check_kubernetes_release "$stable_url")
            ;;
        *)
            echo "::warning::Unknown check type: $check_type"
            return
            ;;
    esac
    
    # Handle empty latest version
    if [[ -z "$latest_version" ]]; then
        echo "::warning::Could not find latest version for $display_name"
        latest_version="$current_version"
    fi
    
    # Compare versions
    if [[ "$current_version" != "$latest_version" ]]; then
        has_update="true"
        UPDATES_FOUND=$((UPDATES_FOUND + 1))
        echo "::notice::$display_name update available: $current_version → $latest_version"
    fi
    
    CHECKS_RUN=$((CHECKS_RUN + 1))
    
    # Add to results
    RESULTS=$(echo "$RESULTS" | jq --arg name "$tool_name" \
        --arg display "$display_name" \
        --arg current "$current_version" \
        --arg latest "$latest_version" \
        --arg has_update "$has_update" \
        --arg action "$update_action" \
        '. + [{name: $name, display_name: $display, current_version: $current, latest_version: $latest, has_update: ($has_update == "true"), update_action: $action}]')
    
    # GitHub Actions annotations
    if [[ "$has_update" == "true" ]]; then
        echo "::notice::$display_name update available: $current_version → $latest_version"
    fi
}

# Run checks
echo "=== Dependency Version Check ==="
echo "Checking $VERSIONS_JSON"
echo ""

# Get tool names from JSON
TOOL_NAMES=$(jq -r '.tools[].name' "$VERSIONS_JSON")
while IFS= read -r tool_name; do
    check_tool "$tool_name"
done <<< "$TOOL_NAMES"

echo ""
echo "=== Summary ==="
echo "Checks run: $CHECKS_RUN"
echo "Updates found: $UPDATES_FOUND"

# Output for GitHub Actions
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "updates_found=$UPDATES_FOUND" >> "$GITHUB_OUTPUT"
    echo "checks_run=$CHECKS_RUN" >> "$GITHUB_OUTPUT"
    echo "results=$(echo "$RESULTS" | jq -c .)" >> "$GITHUB_OUTPUT"
fi

# JSON output
if [[ "$JSON_OUTPUT" == "true" ]]; then
    echo ""
    echo "=== JSON Results ==="
    echo "$RESULTS" | jq .
fi

# Exit with error if updates found (for CI)
if [[ "$UPDATES_FOUND" -gt 0 && "${FAIL_ON_UPDATE:-false}" == "true" ]]; then
    exit 1
fi

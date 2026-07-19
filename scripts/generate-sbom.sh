#!/bin/bash
# generate-sbom.sh - Generate Software Bill of Materials from tools manifest
# Reads sbom-tools.json and queries each tool's version
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TOOLS_JSON="${REPO_ROOT}/sbom-tools.json"

# Check dependencies
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required" >&2
    exit 1
fi

if [[ ! -f "$TOOLS_JSON" ]]; then
    echo "Error: tools manifest not found at $TOOLS_JSON" >&2
    exit 1
fi

# Header
cat <<'HEADER'
Zabbix Proxy SQLite3 AV Edition
Software Bill of Materials (SBOM)
=================================
HEADER
echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "Platform: $(uname -srm)"
echo ""

# Process each section
current_section=""
jq -r '.tools[] | "\(.section)|\(.name)|\(.command)"' "$TOOLS_JSON" | while IFS='|' read -r section name cmd; do
    # Print section header
    if [[ "$section" != "$current_section" ]]; then
        if [[ -n "$current_section" ]]; then
            echo ""
        fi
        description=$(jq -r --arg s "$section" '.sections[$s] // "Unknown"' "$TOOLS_JSON")
        echo "=== $section ==="
        echo "$description"
        echo ""
        current_section="$section"
    fi

    # Execute command and capture output
    version_info=""
    if output=$(eval "$cmd" 2>/dev/null | head -1); then
        version_info="$output"
    else
        version_info="[not available]"
    fi
    echo "  $name: $version_info"
done

echo ""
echo "================================="
echo "End of Software Bill of Materials"

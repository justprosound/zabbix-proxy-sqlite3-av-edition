#!/bin/bash

set -e
set -o pipefail

# Fetch Zabbix version data
echo "Fetching data from Zabbix API..."
if ! curl -s -f -S "https://services.zabbix.com/updates/v1" > .github/zabbix-versions.json; then
  echo "::error::Failed to fetch Zabbix version data from API"
  exit 1
fi

# Validate the JSON response
if ! jq . .github/zabbix-versions.json > /dev/null; then
  echo "::error::Invalid JSON received from Zabbix API"
  cat .github/zabbix-versions.json | head -n 50
  exit 1
fi

# Extract supported versions with proper validation
JQ_FILTER='.versions[] | select(.end_of_full_support == false) |
  if (.latest_release != null) and (.latest_release.release != null) then
    .latest_release.release
  else
    empty
  end'
SUPPORTED_VERSIONS=$(jq -r "$JQ_FILTER" .github/zabbix-versions.json | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V)

if [ -z "$SUPPORTED_VERSIONS" ]; then
  echo "::error::No supported versions found in Zabbix API response"
  cat .github/zabbix-versions.json | jq .
  exit 1
fi

# Identify LTS version (x.0.x format)
# LTS = current LTS release (usually x.0.x format from upstream Zabbix)
LTS_VERSION=""

# First, verify we have valid versions to work with
if [ -n "$SUPPORTED_VERSIONS" ]; then
  # Sort versions to find highest x.0.x version
  for VERSION in $(echo "$SUPPORTED_VERSIONS" | sort -Vr); do
    # Skip empty or invalid versions
    [[ -z "$VERSION" ]] || ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && continue

    MINOR=$(echo "$VERSION" | cut -d. -f2)
    if [[ "$MINOR" == "0" ]]; then
      # Found an LTS version, use the highest one (sorted in reverse)
      LTS_VERSION="$VERSION"
      echo "Found LTS version: $LTS_VERSION (x.0.x pattern - current LTS release)"
      break
    fi
  done

  # Fallback if no LTS found - still need to define a current LTS release
  if [[ -z "$LTS_VERSION" ]]; then
    # Use oldest supported version as LTS when no x.0.x pattern exists
    LTS_VERSION=$(echo "$SUPPORTED_VERSIONS" | sort -V | head -n1)
    echo "No LTS version with x.0.x pattern found, using oldest version as current LTS release: $LTS_VERSION"
  fi
else
  echo "::error::No valid versions found to determine LTS version"
  exit 1
fi

# Get latest version (highest version number)
# Latest = highest version number regardless of release date
# But ensure it's actually a valid version
LATEST_VERSION=$(echo "$SUPPORTED_VERSIONS" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)

# Verify we found a valid latest version
if [[ -z "$LATEST_VERSION" ]]; then
  echo "::error::Failed to determine latest version from supported versions list"
  exit 1
fi

echo "Latest version: $LATEST_VERSION (highest version number)"
echo "LTS version: $LTS_VERSION (current LTS release from upstream Zabbix)"
echo "All supported versions: $SUPPORTED_VERSIONS"

# Set outputs for next steps - filter out any empty or invalid entries
# Filter out empty values and ensure each version has a valid format (x.y.z)
CLEAN_VERSIONS=$(echo "$SUPPORTED_VERSIONS" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V)
echo "Filtered versions (removing empty or invalid entries): $CLEAN_VERSIONS"

echo "latest_version=$LATEST_VERSION" >> "$GITHUB_OUTPUT"
echo "lts_version=$LTS_VERSION" >> "$GITHUB_OUTPUT"
echo "all_versions=$(echo "$CLEAN_VERSIONS" | tr '\n' ',')" >> "$GITHUB_OUTPUT"

# Add to step summary
echo "## Zabbix Version Detection" >> $GITHUB_STEP_SUMMARY
echo "| Type | Version | Description |" >> $GITHUB_STEP_SUMMARY
echo "| ---- | ------- | ----------- |" >> $GITHUB_STEP_SUMMARY
echo "| Latest | $LATEST_VERSION | Highest version number (e.g., 7.2.7 > 7.0.13) |" >> $GITHUB_STEP_SUMMARY
echo "| LTS | $LTS_VERSION | Current LTS release from upstream Zabbix |" >> $GITHUB_STEP_SUMMARY
echo "| All Supported | $(echo "$SUPPORTED_VERSIONS" | tr '\n' ', ') | All versions tracked by upstream Zabbix |" >> $GITHUB_STEP_SUMMARY

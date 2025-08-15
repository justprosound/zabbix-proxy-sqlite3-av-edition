#!/bin/bash

set -e
set -o pipefail

# Reuse the clean, validated versions from the previous step
SUPPORTED_VERSIONS="${ALL_VERSIONS}"
# Convert from comma-separated back to newline-separated
SUPPORTED_VERSIONS=$(echo "$SUPPORTED_VERSIONS" | tr ',' '\n')
LTS_VERSION="${LTS_VERSION}"

# Create the matrix JSON with proper string escaping
echo "Building matrix with these versions: $SUPPORTED_VERSIONS"
echo "LTS version (current LTS release): $LTS_VERSION"

# Use jq to properly create and escape the JSON - ensure all values are treated as strings
# Get the latest version (highest version number)
LATEST_VERSION=$(echo "$SUPPORTED_VERSIONS" | sort -V | tail -n1)

# Create matrix with LTS, Latest, and highest version per major.minor flags
# Group versions by major.minor and find highest patch version in each group
echo "Finding highest patch version for each major.minor series..."
declare -A HIGHEST_PATCH
for VERSION in $SUPPORTED_VERSIONS; do
  # Skip empty or invalid versions
  [[ -z "$VERSION" ]] && continue
  [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && continue

  MAJOR_MINOR=$(echo "$VERSION" | cut -d. -f1,2)
  # Skip invalid major.minor values
  [[ ! "$MAJOR_MINOR" =~ ^[0-9]+\.[0-9]+$ ]] && continue

  CURRENT_HIGHEST="${HIGHEST_PATCH[$MAJOR_MINOR]}"

  # If no version is set for this major.minor or the current version is higher
  if [[ -z "$CURRENT_HIGHEST" || $(echo -e "$VERSION\n$CURRENT_HIGHEST" | sort -V | tail -n1) == "$VERSION" ]]; then
    HIGHEST_PATCH[$MAJOR_MINOR]="$VERSION"
    echo "Setting $VERSION as highest for $MAJOR_MINOR series"
  fi
done

# Display the highest patch versions we found
echo "Highest patch versions for each major.minor series:"
for MAJOR_MINOR in "${!HIGHEST_PATCH[@]}"; do
  echo "  $MAJOR_MINOR => ${HIGHEST_PATCH[$MAJOR_MINOR]}"
done

# Create the matrix JSON with proper version tagging logic
# Build the matrix JSON manually to avoid any jq parsing issues
echo "Building matrix data structure..."
MATRIX_JSON='{"include": ['

# Counter to manage commas
COUNT=0
TOTAL=$(echo "$SUPPORTED_VERSIONS" | wc -w)

for VERSION in $SUPPORTED_VERSIONS; do
  # Skip empty lines
  [[ -z "$VERSION" ]] && continue
  # Skip invalid versions
  [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && continue

  # Extract major.minor
  MAJOR_MINOR=$(echo "$VERSION" | cut -d. -f1,2)

  # Check for LTS and latest flags
  IS_LTS="false"
  IS_LATEST="false"
  [[ "$VERSION" == "$LTS_VERSION" ]] && IS_LTS="true"
  [[ "$VERSION" == "$LATEST_VERSION" ]] && IS_LATEST="true"

  # Add this version to the matrix
  # We're removing is_latest and keeping is_lts consistent with the workflow input parameter
  MATRIX_JSON+='{"zabbix_version": "'$VERSION'", "major_minor": "'$MAJOR_MINOR'", "is_lts": "'$IS_LTS'"}'

  # Add comma if not the last item
  COUNT=$((COUNT + 1))
  [[ $COUNT -lt $TOTAL ]] && MATRIX_JSON+=', '
done

MATRIX_JSON+=']}'

# Format for display
echo "Generated matrix with proper version tagging (LTS = current LTS release, Latest = highest version number):"

# Output and validate the matrix
# Pretty print for logs
echo "$MATRIX_JSON" | jq .

# Validate JSON format with a simple check
if ! echo "$MATRIX_JSON" | jq . > /dev/null; then
  echo "::error::Generated matrix is not valid JSON. Check the matrix generation logic."
  echo "Raw matrix: $MATRIX_JSON"
  exit 1
fi

# Validate content
INCLUDE_COUNT=$(echo "$MATRIX_JSON" | jq '.include | length')
if [[ "$INCLUDE_COUNT" -lt 1 ]]; then
  echo "::error::Matrix JSON is invalid: No items in 'include' array"
  echo "$MATRIX_JSON" | jq .
  exit 1
fi

# Log what was found
echo "Found $INCLUDE_COUNT version(s) for the build matrix"

# Show the first matrix item for validation
if [[ "$INCLUDE_COUNT" -gt 0 ]]; then
  FIRST_ITEM=$(echo "$MATRIX_JSON" | jq -r '.include[0]')
  echo "First matrix item (for validation): $FIRST_ITEM"
fi

echo "matrix=$MATRIX_JSON" >> "$GITHUB_OUTPUT"

# Add validation info to workflow summary
echo "## Matrix Generation Summary" >> $GITHUB_STEP_SUMMARY
echo "| Version | Major.Minor | Is LTS | Latest Version |" >> $GITHUB_STEP_SUMMARY
echo "| ------- | ----------- | ------ | -------------- |" >> $GITHUB_STEP_SUMMARY
for VERSION in $SUPPORTED_VERSIONS; do
  [[ -z "$VERSION" ]] && continue
  [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && continue
  MAJOR_MINOR=$(echo "$VERSION" | cut -d. -f1,2)
  IS_LTS="No"
  LATEST_FLAG=""
  if [[ "$VERSION" == "$LTS_VERSION" ]]; then IS_LTS="Yes"; fi
  if [[ "$VERSION" == "$LATEST_VERSION" ]]; then LATEST_FLAG="✓ (Latest)"; fi
  echo "| $VERSION | $MAJOR_MINOR | $IS_LTS | $LATEST_FLAG |" >> $GITHUB_STEP_SUMMARY
done

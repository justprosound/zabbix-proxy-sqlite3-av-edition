#!/bin/bash

set -e
set -o pipefail

echo "Reading MIBs configuration from mibs.json..."
if [ ! -f "mibs/mibs.json" ]; then
  echo "Error: mibs/mibs.json not found"
  exit 1
fi
MIB_COUNT=$(jq '.mibs | length' mibs/mibs.json)
echo "Found $MIB_COUNT MIB entries to process"

# Initialize counters
DOWNLOADED=0
SKIPPED=0
FAILED=0
UPDATED=0

# Process each MIB entry
for i in $(seq 0 $((MIB_COUNT-1))); do
  NAME=$(jq -r ".mibs[$i].name" mibs/mibs.json)
  URL=$(jq -r ".mibs[$i].url" mibs/mibs.json)
  DESCRIPTION=$(jq -r ".mibs[$i].description" mibs/mibs.json)

  echo "Processing MIB: $NAME ($DESCRIPTION)"
  echo "URL: $URL"

  # Determine file extension based on URL or default to .txt
  if [[ "$URL" == *".mib" ]]; then
    EXT="mib"
  else
    EXT="txt"
  fi

  OUTPUT_FILE="mibs/$NAME.$EXT"

  # Download the MIB file
  echo "Downloading MIB to $OUTPUT_FILE..."
  HTTP_CODE=$(curl -s -L -w "%{http_code}" -o "$OUTPUT_FILE" "$URL")

  # Check if download was successful
  if [[ "$HTTP_CODE" == "200" ]]; then
    if [[ -f "$OUTPUT_FILE" ]]; then
      FILESIZE=$(stat -c%s "$OUTPUT_FILE")
      echo "Download successful: $FILESIZE bytes"
      # Calculate SHA256 checksum for the downloaded file
      sha256sum "$OUTPUT_FILE" | cut -d' ' -f1 > "$OUTPUT_FILE.sha256"
      DOWNLOADED=$((DOWNLOADED+1))
    else
      echo "Error: Downloaded file doesn't exist"
      FAILED=$((FAILED+1))
    fi
  else
    echo "Error: Download failed with HTTP code $HTTP_CODE"
    FAILED=$((FAILED+1))
  fi
done

# Output summary
echo "Download summary:"
echo "- Downloaded: $DOWNLOADED"
echo "- Updated: $UPDATED"
echo "- Skipped: $SKIPPED"
echo "- Failed: $FAILED"

# Exit with error if any downloads failed
if [[ $FAILED -gt 0 ]]; then
  exit 1
fi

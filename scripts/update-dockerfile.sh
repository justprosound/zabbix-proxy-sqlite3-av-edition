#!/bin/bash

set -e
set -o pipefail

LATEST_VERSION="${LATEST_VERSION}"
echo "Updating Dockerfile with latest version: $LATEST_VERSION"

# Check current version in Dockerfile
CURRENT_VERSION=$(grep -oP 'ARG ZABBIX_VERSION=ubuntu-\K[0-9]+\.[0-9]+\.[0-9]+' Dockerfile || echo "unknown")
echo "Current version in Dockerfile: $CURRENT_VERSION"

if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
  echo "Version needs updating from $CURRENT_VERSION to $LATEST_VERSION"

  # Update the Dockerfile
  sed -i "s/ARG ZABBIX_VERSION=ubuntu-[0-9]\+\.[0-9]\+\.[0-9]\+/ARG ZABBIX_VERSION=ubuntu-$LATEST_VERSION/" Dockerfile

  # Verify the change
  NEW_VERSION=$(grep -oP 'ARG ZABBIX_VERSION=ubuntu-\K[0-9]+\.[0-9]+\.[0-9]+' Dockerfile || echo "error")
  if [[ "$NEW_VERSION" == "$LATEST_VERSION" ]]; then
    echo "✅ Successfully updated Dockerfile to version $LATEST_VERSION"

    # Commit and push the changes
    git config --local user.email "github-actions[bot]@users.noreply.github.com"
    git config --local user.name "github-actions[bot]"
    git add Dockerfile

    # Only commit if there are changes
    if git diff --staged --quiet; then
      echo "No changes to commit"
    else
      git commit -m "chore: update Zabbix version to $LATEST_VERSION [skip ci]"
      git push
      echo "Pushed Dockerfile update to repository"
    fi
  else
    echo "::warning::Failed to update Dockerfile, got version $NEW_VERSION instead of $LATEST_VERSION"
  fi
else
  echo "Dockerfile already contains the latest version $LATEST_VERSION. No update needed."
fi

# Add to step summary
echo "## Dockerfile Version Update" >> $GITHUB_STEP_SUMMARY
echo "| Original Version | New Version | Status |" >> $GITHUB_STEP_SUMMARY
echo "| --------------- | ---------- | ------ |" >> $GITHUB_STEP_SUMMARY
if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
  echo "| $CURRENT_VERSION | $LATEST_VERSION | Updated ✅ |" >> $GITHUB_STEP_SUMMARY
else
  echo "| $CURRENT_VERSION | $CURRENT_VERSION | Already up to date ✓ |" >> $GITHUB_STEP_SUMMARY
fi

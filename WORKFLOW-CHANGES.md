# GitHub Workflow Consolidation

This document outlines the changes made to consolidate and clean up GitHub workflows in the zabbix-proxy-sqlite3-av-edition repository.

## Issues Identified

1. **Redundant Workflow Files**:
   - Multiple workflow files with overlapping functionality
   - Inconsistent naming conventions (some with `__` prefix, some without)
   - Duplicate logic across workflows

2. **CI/CD Pipeline Redundancy**:
   - `ci-cd-pipeline.yml` and `ci-release.yml` had similar purposes
   - `build-container.yml` and `__build-container.yml` duplicated functionality

3. **Documentation Updates**:
   - Documentation updating was triggered from multiple places, potentially causing conflicts

4. **Security Scanning Redundancy**:
   - Security scanning performed in multiple places with different tools

## Changes Made

1. **Standardized Naming Convention**:
   - Removed `__` prefix from all workflow files
   - Used descriptive names for all workflow files

2. **Consolidated Main CI/CD Pipeline**:
   - Created a single `main-ci.yml` that combines functionality from:
     - `ci-cd-pipeline.yml`
     - `ci-release.yml`

3. **Standardized Reusable Workflows**:
   - Renamed reusable workflows for consistency:
     - `__version-detection.yml` → `version-detection.yml`
     - `__check-changes.yml` → `check-changes.yml`
     - `__update-docs.yml` → `update-docs.yml`
     - `__build-container.yml` → `build-container.yml`

4. **Removed Redundant Workflows**:
   - Removed `ci-cd-pipeline.yml` (replaced by `main-ci.yml`)
   - Removed `ci-release.yml` (replaced by `main-ci.yml`)
   - Removed `__build-container.yml` (functionality merged into `build-container.yml`)
   - Removed other redundant workflows that duplicated functionality

5. **Security Scanning Consolidation**:
   - Kept `anchore-scan.yml` as a standalone workflow for manual security scanning
   - Consolidated security scanning into the build container workflow

## Workflow Dependencies

The new workflow structure follows this pattern:

```
main-ci.yml
 ├─ version-detection.yml
 ├─ download-mibs.yml (inline)
 ├─ check-changes.yml
 ├─ build-container.yml (for each version in matrix)
 └─ update-docs.yml
```

## Benefits

1. **Simplified Maintenance**:
   - Fewer workflow files to maintain
   - Consistent naming convention
   - Clear separation of concerns

2. **Reduced Duplication**:
   - No duplicate logic across workflows
   - Single source of truth for each function

3. **Better Documentation**:
   - Clearer workflow relationships
   - Standardized naming makes it easier to understand the purpose of each workflow

4. **Improved Reliability**:
   - Fewer potential points of failure
   - More consistent behavior across different triggers

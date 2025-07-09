# Workflow Files Status

The following workflow files have been retained after consolidation:

1. `anchore-scan.yml` - For on-demand security scanning
2. `build-container.yml` - For building and publishing container images
3. `check-changes.yml` - For checking if rebuilds are needed
4. `download-mibs.yml` - For downloading SNMP MIB files
5. `main-ci.yml` - Main CI/CD pipeline
6. `pre-commit.yml` - For code quality checks
7. `update-docs.yml` - For updating documentation
8. `version-detection.yml` - For detecting Zabbix versions

## Changes Made

1. **Consolidated Main Workflow**:
   - Created `main-ci.yml` that combines functionality from `ci-cd-pipeline.yml` and `ci-release.yml`

2. **Standardized Naming**:
   - Removed `__` prefix from workflow file names
   - Renamed files for consistency

3. **Removed Redundant Files**:
   - Removed `__build-container.yml` in favor of `build-container.yml`
   - Removed `__check-changes.yml` in favor of `check-changes.yml`
   - Removed `__cleanup.yml` as its functionality is incorporated elsewhere
   - Removed `__dockerhub-tags.yml` as its functionality is incorporated elsewhere
   - Removed `__update-docs.yml` in favor of `update-docs.yml`
   - Removed `__version-detection.yml` in favor of `version-detection.yml`
   - Removed `ci-cd-pipeline.yml` in favor of `main-ci.yml`
   - Removed `ci-release.yml` in favor of `main-ci.yml`

4. **Documentation Updates**:
   - Created `WORKFLOW-CHANGES.md` to document workflow changes
   - Created `CONSOLIDATION-REPORT.md` with a summary of changes
   - Updated README.md to reference the new workflow structure
   - Updated status badge to point to the new main workflow

These changes improve the maintainability and clarity of the CI/CD pipeline while reducing redundancy and potential points of failure.

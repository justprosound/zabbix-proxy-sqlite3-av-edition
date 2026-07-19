# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Architecture
- Multi-stage Dockerfile with 5 named stages (base, dependencies, scripts, sbom, final)
- Version checking consolidation via `versions.json` and `scripts/check-dependencies.sh`
- Shell wrapper security hardening via shared `scripts/validate.sh` module
- SBOM decoupling via `sbom-tools.json` and `scripts/generate-sbom.sh`
- CI/CD pipeline orchestrator via `.github/workflows/pipeline.yml`

### Security
- Pinned all GitHub Actions to SHA commits (checkout, setup-python, upload-artifact, codeql, scorecard, etc.)
- Updated `dependabot/fetch-metadata` from v2.5.0 to v3.1.0
- Fixed CloudflarePyCLI version detection bug (`$NF` -> `$1`)
- Non-root execution (UID 1997) with minimal attack surface

### Dependencies
- Bump Zabbix upstream from 7.4.5 to 7.4.12
- Bump actions/checkout to v7
- Bump actions/upload-artifact to v5
- Bump actions/setup-python to v6
- Bump requests from 2.32.3 to 2.34.2
- Bump charset-normalizer from 3.4.4 to 3.4.9
- Bump github/codeql-action to 4.36.2
- Bump softprops/action-gh-release to 2.6.1
- Bump docker/build-push-action to 6.19.2
- Bump docker/login-action to 3.7.0

## [7.4.5] - 2026-06-01

### Changed
- Zabbix upstream base image 7.4.5

### Dependencies
- Bump actions/checkout from 6.0.1 to 6.0.2
- Bump actions/setup-python from 6.1.0 to 6.2.0
- Bump urllib3 from 2.5.0 to 2.6.2
- Bump dependabot/fetch-metadata from 2.4.0 to 2.5.0

## [7.4.4] - 2026-05-01

### Changed
- Zabbix upstream base image 7.4.4

## [7.4.3] - 2026-04-01

### Changed
- Zabbix upstream base image 7.4.3

## [7.4.2] - 2026-03-01

### Changed
- Zabbix upstream base image 7.4.2

## [7.4.1] - 2026-02-01

### Changed
- Zabbix upstream base image 7.4.1

## [7.4.0] - 2026-01-01

### Changed
- Zabbix upstream base image 7.4.0

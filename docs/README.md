# Documentation

This directory contains project documentation.

## Quick Links

- **[Installation Guide](INSTALL.md)** - How to build and run the container
- **[Configuration Guide](CONFIGURATION.md)** - Environment variables and tuning
- **[Security Policy](../SECURITY.md)** - Vulnerability reporting and security features
- **[Contributing Guide](../CONTRIBUTING.md)** - How to contribute to this project
- **[Changelog](../CHANGELOG.md)** - Release history and notable changes

## Architecture

This project builds a Zabbix Proxy container with SQLite3 backend, enhanced for AV system monitoring.

### Build System

The container is built using GitHub Actions CI/CD pipeline with multi-architecture support (amd64/arm64).

### Security Model

- Non-root execution (UID 1997)
- Pinned dependencies (GitHub Actions pinned to SHA)
- Automated vulnerability scanning (Trivy, Grype, CodeQL)
- Software Bill of Materials (SBOM) generated per release

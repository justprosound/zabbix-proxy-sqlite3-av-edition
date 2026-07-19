# Multi-stage Dockerfile for Zabbix Proxy SQLite3 AV Edition
# Global hadolint ignore directives
# hadolint global ignore=DL3002,DL3003,DL3008,DL4001,DL3047,DL4006,SC2015,SC2016
ARG ZABBIX_VERSION=ubuntu-7.4.5
ARG OOKLA_VERSION=1.2.0

# =============================================================================
# Stage: uv - Python package installer (build dependency)
# =============================================================================
FROM ghcr.io/astral-sh/uv:latest AS uv

# =============================================================================
# Stage: base - System packages and configuration
# =============================================================================
FROM zabbix/zabbix-proxy-sqlite3:${ZABBIX_VERSION} AS base

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    MIBS=+ALL

# Create directory for custom SNMP MIBs
RUN mkdir -p /usr/share/snmp/mibs/custom && \
    chown -R 1997:1997 /usr/share/snmp/mibs/custom && \
    chmod 755 /usr/share/snmp/mibs/custom

# Configure apt sources and preferences (before any apt-get update)
RUN if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
      rm -f /etc/apt/sources.list.d/ubuntu.sources; \
    fi && \
    echo "deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu noble-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "# Priority on security updates" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    mkdir -p /etc/apt/preferences.d && \
    echo "Package: *" > /etc/apt/preferences.d/99-security-updates && \
    echo "Pin: release l=Ubuntu,o=Ubuntu,a=noble-security" >> /etc/apt/preferences.d/99-security-updates && \
    echo "Pin-Priority: 990" >> /etc/apt/preferences.d/99-security-updates && \
    echo "Package: *" > /etc/apt/preferences.d/97-backports && \
    echo "Pin: release a=noble-backports" >> /etc/apt/preferences.d/97-backports && \
    echo "Pin-Priority: 990" >> /etc/apt/preferences.d/97-backports && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /etc/apt/apt.conf.d && \
    echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99-no-translations

# Install all system packages in a single layer
# hadolint ignore=DL3008,DL4001,DL3047
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # Network diagnostic tools
    iputils-ping \
    iputils-tracepath \
    traceroute \
    fping \
    dnsutils \
    nmap \
    netcat-openbsd \
    mtr \
    iproute2 \
    tcpdump \
    # SNMP monitoring
    snmp \
    snmp-mibs-downloader \
    # Download and system tools
    curl \
    wget \
    ca-certificates \
    nano \
    # JSON processing
    jq \
    jo \
    # Scripting support
    expect \
    # Python support
    python3 \
    python3-pip \
    python3-setuptools \
    python3-venv \
    # Package management
    gnupg \
    # Security tools
    apt-transport-https \
    dirmngr && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure SNMP to include custom MIBs
RUN echo "# SNMP configuration for custom MIBs" > /etc/snmp/snmp.conf && \
    echo "mibdirs /usr/share/snmp/mibs:/usr/share/snmp/mibs/custom" >> /etc/snmp/snmp.conf && \
    echo "mibs +ALL" >> /etc/snmp/snmp.conf && \
    chown root:root /etc/snmp/snmp.conf && \
    chmod 644 /etc/snmp/snmp.conf

# =============================================================================
# Stage: speedtest - Cloudflare and Ookla speedtest tools
# =============================================================================
FROM base AS speedtest

ARG OOKLA_VERSION
WORKDIR /tmp

# Copy Python requirements and uv binary
COPY requirements-docker.txt /tmp/requirements-docker.txt
COPY --from=uv /uv /usr/local/bin/uv

# Install Cloudflare Speedtest Python CLI (cloudflarepycli)
RUN python3 -m venv /opt/venv && \
    uv pip install --python /opt/venv -r /tmp/requirements-docker.txt && \
    echo '#!/bin/bash' > /usr/local/bin/cfspeedtest && \
    echo '/opt/venv/bin/cfspeedtest "$@"' >> /usr/local/bin/cfspeedtest && \
    chmod +x /usr/local/bin/cfspeedtest && \
    rm -f /tmp/requirements-docker.txt

# Install Ookla Speedtest CLI binary
# hadolint ignore=DL3003
RUN { \
        set +e; \
        mkdir -p /tmp/speedtest && \
        cd /tmp/speedtest && \
        curl -fsSL --retry 3 --retry-delay 2 "https://install.speedtest.net/app/cli/ookla-speedtest-${OOKLA_VERSION}-linux-x86_64.tgz" \
            -o speedtest.tgz && \
        tar -xzf speedtest.tgz -C /tmp/speedtest && \
        if [ -f "/tmp/speedtest/speedtest" ]; then \
            mv /tmp/speedtest/speedtest /usr/local/bin/ && \
            chmod +x /usr/local/bin/speedtest && \
            mkdir -p /root/.config/ookla && \
            echo '{"Settings":{"LicenseAccepted": "604ec27f828456331ebf441826292c49276bd3c1bee1a2f65a6452f505c4061c"}}' > /root/.config/ookla/speedtest-cli.json; \
            echo "Successfully installed Ookla Speedtest CLI"; \
        else \
            echo "Warning: Failed to install Ookla Speedtest CLI - will use alternative only"; \
        fi && \
        rm -rf /tmp/speedtest; \
        set -e; \
    }

# =============================================================================
# Stage: kubectl - Kubernetes management tool
# =============================================================================
FROM base AS kubectl

ARG KUBECTL_VERSION=v1.35.0
ARG KUBECTL_SHA256=a2e984a18a0c063279d692533031c1eff93a262afcc0afdc517375432d060989

RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    echo "${KUBECTL_SHA256} kubectl" | sha256sum --check && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# =============================================================================
# Stage: sbom - Generate Software Bill of Materials
# =============================================================================
FROM speedtest AS sbom

COPY --from=kubectl /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY sbom-tools.json /tmp/sbom-tools.json
COPY scripts/generate-sbom.sh /usr/local/bin/generate-sbom.sh
RUN chmod +x /usr/local/bin/generate-sbom.sh && \
    generate-sbom.sh > /usr/local/share/zabbix-proxy-sbom.txt 2>/dev/null || true

# =============================================================================
# Final stage - Assemble all components
# =============================================================================
FROM base AS final

# Copy speedtest tools from speedtest stage
COPY --from=speedtest /opt/venv /opt/venv
COPY --from=speedtest /usr/local/bin/cfspeedtest /usr/local/bin/cfspeedtest
COPY --from=speedtest /usr/local/bin/speedtest /usr/local/bin/speedtest

# Copy kubectl from kubectl stage
COPY --from=kubectl /usr/local/bin/kubectl /usr/local/bin/kubectl

# Copy SBOM from sbom stage
RUN mkdir -p /usr/local/share
COPY --from=sbom /usr/local/share/zabbix-proxy-sbom.txt /usr/local/share/zabbix-proxy-sbom.txt

# Copy custom scripts to Zabbix external scripts directory
COPY --chown=1997 --chmod=0711 ./scripts/* /usr/lib/zabbix/externalscripts/

# Copy custom SNMP MIBs (if any exist)
COPY --chown=1997 --chmod=0644 ./mibs/ /usr/share/snmp/mibs/custom/
RUN rm -f /usr/share/snmp/mibs/custom/README.md

# Set appropriate permissions
# hadolint ignore=SC2015
RUN chmod -R 755 /usr/local/bin/* && \
    mkdir -p /var/run/zabbix && \
    chown -R 1997:1997 /var/run/zabbix && \
    chown -R 1997:1997 /usr/local/share && \
    chmod 755 /usr/local/share && \
    chmod 664 /usr/local/share/zabbix-proxy-sbom.txt && \
    find / -perm /6000 -type f -exec chmod a-s {} \; || true

# Add container labels following OCI standards
LABEL org.opencontainers.image.title="Zabbix Proxy SQLite3 for AV Systems" \
      org.opencontainers.image.description="Zabbix Proxy with SQLite3 database for AV Systems" \
      org.opencontainers.image.licenses="AGPL-3.0" \
      org.opencontainers.image.vendor="Zabbix" \
      org.opencontainers.image.base.name="zabbix/zabbix-proxy-sqlite3"

# Switch to Zabbix user (UID 1997)
USER 1997

# Define health check
# hadolint ignore=DL3047,DL4001
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --progress=dot:giga --tries=1 --spider 127.0.0.1:10051 || exit 1

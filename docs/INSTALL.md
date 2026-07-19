# Installation Guide

## Prerequisites

- Docker or Podman
- Access to a Zabbix server (port 10051)

## Quick Start

### Using Docker

```bash
docker pull ghcr.io/justprosound/zabbix-proxy-sqlite3-av-edition:latest
docker run -d \
  --name zabbix-proxy-av \
  --restart unless-stopped \
  -p 10051:10051 \
  -e ZBX_SERVER_HOST=your-zabbix-server.example.com \
  -e ZBX_HOSTNAME=av-proxy-01 \
  ghcr.io/justprosound/zabbix-proxy-sqlite3-av-edition:latest
```

### Building from Source

```bash
git clone https://github.com/justprosound/zabbix-proxy-sqlite3-av-edition.git
cd zabbix-proxy-sqlite3-av-edition
docker build -t zabbix-proxy-av:local .
```

## Available Tags

| Tag | Description |
|-----|-------------|
| `latest` | Highest version number (7.2.x) |
| `lts` | LTS version (7.0.x) |
| `7.4.x` | Specific version |

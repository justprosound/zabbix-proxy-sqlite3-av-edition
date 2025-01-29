# Zabbix Proxy SQLite3 for AV System Monitoring

This is a thin wrapper around the Zabbix Proxy SQLite3 container that is extended & customized for monitoring AV systems.
It includes a few additional binaries and scripts to make it easier to monitor AV systems.

## Usage

```bash
docker pull ghcr.io/hyperscaleav/zabbix-proxy-sqlite3:latest
docker run -d --name zabbix-proxy-sqlite3 -p 10051:10051 /
    -e ZBX_SERVER_HOST=<your-Zabbix-Server-fqdn> /
    -e ZBX_HOSTNAME=myproxy /
    -e ZBX_PROXYMODE=0 /
    -e ZBX_SERVER_PORT=10051 /
    -e ZBX_PROXYBUFFERMODE=hybrid /
    -e ZBX_PROXYMEMORYBUFFERAGE=1800 /
    -e ZBX_PROXYMEMORYBUFFERSIZE=256M /
    -e ZBX_ENABLEREMOTECOMMANDS=1 /
    ghcr.io/hyperscaleav/zabbix-proxy-sqlite3:latest
```
It is highly suggested you also deploy a Zabbix Agent alongside the Proxy. 
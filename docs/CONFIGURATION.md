# Configuration Guide

## Environment Variables

### Required Variables

| Variable | Description |
|----------|-------------|
| `ZBX_SERVER_HOST` | Zabbix server hostname or IP |
| `ZBX_HOSTNAME` | Unique proxy identifier |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ZBX_PROXYMODE` | `0` | Proxy mode (0=active, 1=passive) |
| `ZBX_SERVER_PORT` | `10051` | Zabbix server port |
| `ZBX_PROXYBUFFERMODE` | `hybrid` | Buffering strategy |
| `ZBX_PROXYMEMORYBUFFERAGE` | `600` | Memory buffer age (seconds) |
| `ZBX_PROXYMEMORYBUFFERSIZE` | `16M` | Memory buffer size |
| `ZBX_ENABLEREMOTECOMMANDS` | `0` | Enable remote command execution |

## Performance Tuning

For AV environments with high monitoring loads:

```bash
ZBX_PROXYMEMORYBUFFERSIZE=256M
ZBX_PROXYMEMORYBUFFERAGE=1800
```

## Security Considerations

- `ZBX_ENABLEREMOTECOMMANDS` should remain `0` unless explicitly needed
- Container runs as non-root (UID 1997)
- No plaintext secrets in environment variables

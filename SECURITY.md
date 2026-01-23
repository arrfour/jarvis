# Security Considerations

This document outlines security considerations for the Jarvis deployment.

## 🔑 Secrets Management

### Tailscale Auth Keys

Auth keys are stored in `.env` files that are **gitignored**:
- `production/.env` - Contains `TS_AUTHKEY`
- `beta/.env` - Contains `TS_AUTHKEY_BETA`

> [!IMPORTANT]
> **Never commit auth keys to git.** If you accidentally commit secrets, rotate them immediately at https://login.tailscale.com/admin/settings/keys

### Key Rotation Schedule

Tailscale auth keys should be rotated:
- Immediately if compromised
- Every 90 days (keys are set to expire after 90 days by default)
- When team members leave

## 🌐 Network Exposure

### Current Configuration

| Port | Binding | Purpose | Access |
|------|---------|---------|--------|
| 8080 | 0.0.0.0 | Production Web UI | LAN + Tailscale |
| 8081 | 0.0.0.0 | Beta Web UI | LAN + Tailscale |
| 11434 | 0.0.0.0 | Production Ollama API | LAN + Tailscale |
| 11435 | 0.0.0.0 | Beta Ollama API | LAN + Tailscale |

### Restricting Access

To restrict services to Tailscale-only access:
```yaml
# In docker-compose.yaml, change:
ports:
  - "0.0.0.0:8080:80"   # LAN accessible
# To:
ports:
  - "127.0.0.1:8080:80" # Localhost only (Tailscale still works)
```

## 🐳 Container Security

### Privileged Containers

The Tailscale sidecar containers run in **privileged mode**:
```yaml
tailscale-sidecar:
  privileged: true
```

This is **required** for Tailscale to:
- Create TUN devices
- Modify network routing tables
- Manage DNS settings

### CORS Configuration

The Open WebUI container logs a warning:
```
WARNING: CORS_ALLOW_ORIGIN IS SET TO '*'
```

For production deployments with known clients, consider setting specific origins:
```yaml
environment:
  CORS_ALLOW_ORIGIN: "https://jarvis.yourtailnet.ts.net"
```

## 🔒 Best Practices

1. **Auth Keys**: Use separate keys for production and beta
2. **Key Options**: Always create keys with "Reusable" + "Ephemeral"
3. **Device Approval**: Review connected devices regularly at https://login.tailscale.com/admin/machines
4. **Updates**: Keep Tailscale and Open WebUI updated for security patches
5. **Backups**: Backup volume data before major updates

## 📋 Security Checklist

- [ ] Auth keys are not committed to git
- [ ] Auth keys use "Reusable" + "Ephemeral" options
- [ ] Separate keys for production and beta
- [ ] Reviewed connected Tailscale devices
- [ ] Considered restricting ports to 127.0.0.1 if LAN access not needed
- [ ] Documented any custom CORS origins

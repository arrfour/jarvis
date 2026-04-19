# Troubleshooting Guide

## 500 Internal Error via Tailscale FQDN

### Symptoms
- ✅ Application loads fine on `http://localhost:8080` (production) or `http://localhost:8081` (beta)
- ❌ Getting "500 Internal Server Error" when accessing via Tailscale FQDN (`https://jarvis.YOUR_TAILNET.ts.net` or `https://jarvis-beta.YOUR_TAILNET.ts.net`)
- ❌ Frontend loads but API calls fail

### Root Cause
The issue occurs because **Tailscale Serve needs to be explicitly configured** after device approval. Tailscale needs to know where to proxy requests from the tailnet.

### Solution

#### Step 1: Approve the Device
1. Go to https://login.tailscale.com/admin/machines
2. Find `jarvis` (production) and `jarvis-beta` (beta) devices
3. Click the three dots menu and select "Approve"

#### Step 2: Configure Tailscale Serve

Once devices are approved, run these commands on the machine hosting the containers:

**Production (via Tailscale SSH):**
```bash
tailscale serve https / http://localhost:8080
```

**Beta (via Tailscale SSH):**
```bash
tailscale serve https / http://localhost:8081
```

Or if you need to configure it via the admin console, add these serve configurations to your device in the Tailscale admin console.

#### Step 3: Verify
- Access `https://jarvis.YOUR_TAILNET.ts.net` - should work
- Access `https://jarvis-beta.YOUR_TAILNET.ts.net` - should work (red branding)

### Alternative: Use Tailscale Serve Configuration Files

The configuration files are already in place:
- `production/tailscale-serve-config.json` - proxies to port 8080
- `beta/tailscale-serve-config.json` - proxies to port 8081

These can be applied via:
```bash
tailscale serve-config production/tailscale-serve-config.json
```

### Why This Happens

1. **Reusable/Ephemeral Auth Keys** - These auto-approve containers but don't auto-configure Serve
2. **Tailscale Serve requires CLI configuration** - Cannot be set via environment variables alone
3. **Network isolation** - The tailscale-sidecar container has `network_mode: host` to reach localhost services

### Testing Connectivity

**Test direct Docker network access:**
```bash
docker exec nginx-proxy curl http://open-webui2:8080/
```

**Test localhost via nginx:**
```bash
docker exec nginx-proxy curl http://127.0.0.1:8080/
```

**Test from host:**
```bash
curl http://localhost:8080/
```

All should return the Open WebUI HTML page.

---

## Other Common Issues

### Containers Keep Restarting
- **Check logs:** `docker logs [container-name]`
- **Check volumes:** Ensure `production/` and `beta/` directories exist
- **Check env files:** Verify `production/.env` and `beta/.env` have valid Tailscale auth keys

### Nginx 502 Bad Gateway
- **Check upstream:** `docker exec nginx-proxy curl http://open-webui2:8080/`
- **Check networking:** Ensure containers are on the same network
- **Check Open WebUI health:** `docker logs open-webui2`

### Can't Access via Tailscale from Other Devices
- Device not approved in admin console
- Tailscale Serve not configured
- Firewall blocking traffic
- DNS not resolving (check `tailscale status`)

---

## VIP Registrar (`vip-registrar` sidecar)

The `vip-registrar` container registers this machine as a backend for the `svc:jarvis` Tailscale VIP after the app passes its healthcheck, and withdraws cleanly on `docker compose down`.

### Container exits immediately / never registers

**Check logs first:**
```bash
docker logs vip-registrar
```

**Cause 1: Host socket not found**

The sidecar mounts the host's `tailscaled` socket. If Tailscale is only running inside Docker (not natively on the host), the socket won't exist.

```bash
# Verify on the host:
ls -la /var/run/tailscale/tailscaled.sock
```

If missing, either install Tailscale natively on the host, or override the path in `production/.env`:
```bash
TAILSCALE_SOCK=/path/to/custom/tailscaled.sock
```

**Cause 2: Tailscale binary not found or wrong path**

```bash
# Check the default path:
which tailscale
# Override in production/.env if different:
TAILSCALE_BIN=/usr/local/bin/tailscale
```

**Cause 3: Missing `tag:services` ACL tag**

The host must hold `tag:services` on the tailnet and `svc:jarvis` must list `tag:services` in its allowed backends in the Tailscale control plane. Verify at https://login.tailscale.com/admin/acls.

### VIP stays registered after `docker compose down`

The SIGTERM trap in the sidecar should withdraw the VIP automatically. If it doesn't:

```bash
# Manually withdraw on the host:
tailscale serve --service=svc:jarvis --remove https://localhost:443

# Verify it's cleared:
tailscale serve status
```

### VIP registered but traffic not reaching app

- Confirm `open-webui2` passed its healthcheck: `docker inspect open-webui2 | grep -A5 Health`
- Confirm Nginx is running: `docker ps | grep nginx-proxy`
- Check Nginx is reachable: `curl -fsS http://localhost:8080/health`
- Check `tailscale serve status` shows `svc:jarvis` pointing to `https://localhost:443`

### Known limitation (v1)

If `open-webui2` crashes *after* the VIP is registered, the VIP stays advertised (the sidecar is in its sleep loop and unaware of app health). Tailscale's own VIP health checks (liveness re-check) are planned for v2.

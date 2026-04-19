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

## VIP Registration (built into `tailscale-sidecar`)

VIP registration runs inside the `tailscale-sidecar` container via a custom entrypoint script (`production/tailscale-entrypoint.sh`). It starts the Tailscale daemon, polls the app's health endpoint, registers with `svc:jarvis`, and withdraws cleanly on `docker compose down`. No host-native Tailscale installation is required.

### VIP never registers / sidecar stuck at health poll

**Check entrypoint logs:**
```bash
docker logs tailscale-sidecar
```
Look for `[ts-entrypoint]` prefixed lines showing progress.

**App health poll stalling** — the script polls `http://localhost:8080/health` (host network). Check that nginx is up and the app is healthy:
```bash
# From the host:
curl -fsS http://localhost:8080/health

# Full healthcheck status:
docker inspect open-webui2 --format '{{json .State.Health}}' | python3 -m json.tool
```

If the health endpoint path differs, override in `production/.env`:
```bash
APP_HEALTH_URL=http://localhost:8080/
```

**Tailscale not authenticating** — if logs show daemon timeout, check the auth key in `production/.env` is valid and not expired. Rotate at https://login.tailscale.com/admin/settings/keys.

**Missing `tag:services` ACL tag** — the host must hold `tag:services` and `svc:jarvis` must allow that tag in the Tailscale control plane. Verify at https://login.tailscale.com/admin/acls.

### VIP stays registered after `docker compose down`

The SIGTERM trap in the entrypoint script should withdraw the VIP automatically with a 10s grace window. If it doesn't:

```bash
# Manually withdraw via the running container (if still up):
docker exec tailscale-sidecar tailscale serve --service=svc:jarvis --remove https://localhost:443

# Or directly on the host if native tailscale is installed:
tailscale serve --service=svc:jarvis --remove https://localhost:443

# Confirm it's cleared:
docker exec tailscale-sidecar tailscale serve status
```

### VIP registered but traffic not reaching app

- Confirm `open-webui2` passed its healthcheck: `docker inspect open-webui2 --format '{{json .State.Health}}'`
- Confirm Nginx is running: `docker ps | grep nginx-proxy`
- Check Nginx is reachable from the host: `curl -fsS http://localhost:8080/health`
- Confirm VIP backend: `docker exec tailscale-sidecar tailscale serve status` — should show `svc:jarvis → https://localhost:443`

### Overriding VIP defaults

All three registration parameters are configurable via `production/.env` without touching the compose file:

```bash
APP_HEALTH_URL=http://localhost:8080/health   # default
VIP_SERVICE=svc:jarvis                        # default
VIP_BACKEND=https://localhost:443             # default
```

### Known limitation (v1)

If `open-webui2` crashes *after* the VIP is registered, the VIP stays advertised (the entrypoint is in `wait` and unaware of app health changes post-registration). Liveness re-checking is planned for v2.

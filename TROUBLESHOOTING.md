# Troubleshooting Guide

## 500 Internal Error via Tailscale FQDN

### Symptoms
- ✅ Application loads fine on `http://localhost:8080` (production) or `http://localhost:8081` (beta)
- ❌ Getting "500 Internal Server Error" when accessing via Tailscale FQDN (`https://jarvis.tailcd013.ts.net` or `https://jarvis-beta.tailcd013.ts.net`)
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
- Access `https://jarvis.tailcd013.ts.net` - should work
- Access `https://jarvis-beta.tailcd013.ts.net` - should work (red branding)

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

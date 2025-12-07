# Deployment & Portability Guide

This guide helps you deploy Jarvis from WSL Ubuntu to a standalone Linux server with confidence.

## ✅ Portability Checklist

### Already Portable ✅
- ✅ Shell scripts use standard `#!/bin/bash` (works everywhere)
- ✅ No Windows-specific paths (all use Unix conventions)
- ✅ Docker Compose is platform-agnostic
- ✅ All services are containerized (no host dependencies)
- ✅ Configuration files use standard Linux format
- ✅ No CRLF line endings (pure LF)

### Platform-Specific Considerations ⚠️

1. **GPU Support** - WSL2 has NVIDIA GPU passthrough, but not all servers do
2. **Tailscale Sidecar** - Requires Tailscale installed on the host (not in container)
3. **Privileged Mode** - Required for Tailscale, but needs proper permissions
4. **Network Mode** - Uses `host` network mode for Tailscale Serve to work

## 🖥️ Deploying to a Linux Server

### Prerequisites on Target Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose (v2+)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add your user to docker group (avoid sudo)
sudo usermod -aG docker $USER
newgrp docker

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
```

### Step 1: Transfer Repository

```bash
# Option A: Git clone (recommended)
git clone https://github.com/arrfour/jarvis.git
cd jarvis

# Option B: SCP/rsync from WSL
scp -r /home/arr4/openwebuiANDollama user@server:/home/user/jarvis
```

### Step 2: Configure Environment

```bash
cd jarvis

# Copy templates
cp production/.env.example production/.env
cp beta/.env.example beta/.env

# Edit with new auth keys (generate fresh ones!)
nano production/.env      # Add TS_AUTHKEY=tskey-auth-xxxxx
nano beta/.env            # Add TS_AUTHKEY_BETA=tskey-auth-yyyyy
```

⚠️ **Important:** Generate NEW Tailscale auth keys for the target server. Don't reuse keys from WSL - each device needs its own key.

### Step 3: Handle Platform-Specific Configs

#### Option A: Server with NVIDIA GPU ✅
If target server has NVIDIA GPU, everything works as-is:

```bash
./manage.sh start
```

#### Option B: Server without GPU 🚫
If target server has NO GPU, disable GPU support:

**Edit `docker-compose.yaml`:**
```yaml
# Find these sections and comment out gpus:
# open-webui2:
#   gpus: all              ← COMMENT OUT
# open-webui-beta:
#   gpus: all              ← COMMENT OUT
```

Or use the automated fix:

```bash
sed -i 's/    gpus: all/    # gpus: all/g' docker-compose.yaml
sed -i 's/    gpus: all/    # gpus: all/g' production/docker-compose.yaml
sed -i 's/    gpus: all/    # gpus: all/g' beta/docker-compose.yaml
```

Then verify:
```bash
docker-compose --profile prod config | grep -i gpu
# Should show nothing or commented lines
```

### Step 4: Start Services

```bash
# Start both stacks
./manage.sh start

# Or just production
./manage.sh start-prod

# Check status
./manage.sh status
```

### Step 5: Verify Tailscale Connection

```bash
# Check Tailscale status inside production container
docker exec tailscale-sidecar tailscale status

# Should show: connected, with your device listed

# Check Serve configuration
docker exec tailscale-sidecar tailscale serve status
```

### Step 6: Approve Device in Tailscale Admin

1. Go to https://login.tailscale.com/admin/machines
2. Find the new `jarvis` device from your Linux server
3. Approve it
4. Note its Tailscale IP (e.g., `100.85.172.20`)

### Step 7: Access Your Deployment

```bash
# From any device on your Tailnet
curl https://jarvis.YOUR_TAILNET.ts.net

# Or via Tailscale IP if FQDN doesn't work yet
curl http://100.85.172.20:8080
```

## 🔧 Configuration Differences

### localhost vs 127.0.0.1

The current config uses `127.0.0.1` in port bindings, which is correct and portable:

```yaml
ports:
  - "127.0.0.1:8080:80"  # ✅ Correct - binds only to loopback
  - "0.0.0.0:8080:80"    # ❌ Would expose to network
```

This is **intentional** - Tailscale Serve handles external access, nginx is internal-only.

### Environment Variables

Portable environment variable patterns used:

```yaml
# ✅ GOOD - Works everywhere
BACKEND_URL: http://localhost:8080/api

# ✅ GOOD - Works with Docker networks
upstream:
  - service_name:8080

# ❌ AVOID - Won't work in containers
BACKEND_URL: http://192.168.1.100:8080
```

Current setup uses portable patterns throughout.

## 🚨 Common Portability Issues & Fixes

### Issue 1: "Cannot connect to Docker daemon"

**Cause:** Docker not installed or user not in docker group

**Fix:**
```bash
# Install Docker
curl -fsSL https://get.docker.com | sudo sh

# Add user to group
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker ps
```

### Issue 2: "GPU not available" errors

**Cause:** Target server has no GPU

**Fix:**
```bash
# Disable GPU in compose files
sed -i 's/    gpus: all/    # gpus: all/g' docker-compose.yaml
./manage.sh start
```

### Issue 3: "Tailscale: permission denied"

**Cause:** Tailscale not installed or not in PATH

**Fix:**
```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Or manually
sudo apt install tailscale

# Enable Tailscale
sudo systemctl start tailscaled
sudo systemctl enable tailscaled
```

### Issue 4: "Cannot create device: permission denied"

**Cause:** Tailscale needs permissions to create TUN device

**Fix:** Already handled by Docker `privileged: true` and `/dev/net/tun` volume mount. If still failing:

```bash
# Check TUN device
ls -l /dev/net/tun

# Should show: crw-rw-rw- (666 permissions)
# If not:
sudo chmod 666 /dev/net/tun

# Make permanent (create udev rule)
echo 'KERNEL=="tun", MODE="0666"' | sudo tee /etc/udev/rules.d/99-tun.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Issue 5: "Port already in use"

**Cause:** Another service using 8080 or 8081

**Fix:**
```bash
# Check what's using ports
sudo lsof -i :8080
sudo lsof -i :8081

# Either stop that service or change ports in docker-compose.yaml
```

### Issue 6: "Tailscale Serve not working"

**Cause:** Usually due to certificate rate limiting or network issues

**See:** [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) for detailed Serve diagnostics

## 📋 Pre-Deployment Validation

Create a checklist before deploying:

```bash
#!/bin/bash
# pre-deploy-check.sh

echo "=== Portability Validation ==="
echo ""

# Check Docker
echo "✓ Docker version:"
docker --version || (echo "❌ Docker not found"; exit 1)

# Check Docker Compose
echo "✓ Docker Compose version:"
docker-compose --version || (echo "❌ Docker Compose not found"; exit 1)

# Check Tailscale
echo "✓ Tailscale status:"
sudo tailscale status || echo "⚠️  Tailscale not configured yet (OK for first run)"

# Check docker-compose syntax
echo "✓ Validating docker-compose.yaml:"
docker-compose --profile all config > /dev/null && echo "  ✅ Valid"

# Check .env files
echo "✓ Checking .env files:"
[ -f production/.env ] && echo "  ✅ production/.env exists" || echo "  ⚠️  production/.env missing"
[ -f beta/.env ] && echo "  ✅ beta/.env exists" || echo "  ⚠️  beta/.env missing"

# Check GPU (optional)
echo "✓ GPU support:"
docker run --rm --gpus all nvidia/cuda:11.0.3-base nvidia-smi &>/dev/null && \
  echo "  ✅ GPU available" || \
  echo "  ⚠️  GPU not available (disable gpus: all if running on CPU server)"

echo ""
echo "=== Validation Complete ==="
```

Save as `pre-deploy-check.sh`, run with `bash pre-deploy-check.sh`

## 🔄 Backup & Recovery

### Before First Deployment

```bash
# Backup your compose files
tar -czf jarvis-backup-$(date +%Y%m%d).tar.gz \
  docker-compose.yaml \
  production/docker-compose.yaml \
  beta/docker-compose.yaml \
  production/nginx.conf \
  beta/nginx.conf

# Keep this safely
ls -lh jarvis-backup-*.tar.gz
```

### After First Successful Deployment

```bash
# Tag release for this server
git tag -a "server-deployment-$(hostname)-$(date +%Y%m%d)" \
  -m "Deployed to $(hostname) on $(date)"

git push origin "server-deployment-$(hostname)-$(date +%Y%m%d)"
```

## 🚀 Migration Path: WSL → Linux Server

**Timeline for moving from WSL development to Linux production:**

1. **Week 1-2: Development on WSL**
   - Test features on beta stack
   - Validate everything works
   - Commit to git

2. **Week 3: Deployment Prep**
   - Set up Linux server
   - Run pre-deploy check
   - Generate new Tailscale keys

3. **Week 4: Deploy to Server**
   - Clone repo to server
   - Configure .env files
   - Run `./manage.sh start-prod`
   - Test HTTPS access
   - Monitor for 48 hours

4. **Week 5+: Retire WSL Deployment**
   - When satisfied, stop WSL stacks
   - Keep as backup only
   - Git track server version

## 📊 Testing Matrix

| Component | WSL2 | Linux Server | Notes |
|-----------|------|--------------|-------|
| Docker | ✅ | ✅ | Works identically |
| Compose | ✅ | ✅ | Works identically |
| Tailscale | ✅ | ✅ | Needs separate key per device |
| GPU | ✅ (NVIDIA only) | ✅ (varies) | Disable if not available |
| Networking | ✅ | ✅ | host mode works on both |
| Storage | ✅ | ✅ | Docker volumes portable |
| Permissions | ✅ | ✅ | Add user to docker group |

## ✅ Sign-Off Checklist for Production Deployment

Before considering migration complete:

- [ ] Both stacks start without errors: `./manage.sh start`
- [ ] Production accessible via HTTPS FQDN: `https://jarvis.YOUR_TAILNET.ts.net`
- [ ] Beta accessible: `https://jarvis-beta.YOUR_TAILNET.ts.net`
- [ ] Both accessible from other Tailnet devices
- [ ] Logs clean: `./manage.sh logs` shows no errors
- [ ] Models persist across restart: `./manage.sh restart-prod`
- [ ] Settings persist: Create a test conversation, restart, verify it's still there
- [ ] Database accessible: Check Open WebUI settings page loads
- [ ] Tailscale Serve configured: `docker exec tailscale-sidecar tailscale serve status`
- [ ] Backup created and verified
- [ ] Git tag created for deployment: `git tag server-deployed-[date]`

Once all checked, you have a successful, portable, production-ready deployment! 🎉

## 🔗 Related Documentation

- [`README.md`](./README.md) - Main overview
- [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) - Problem solving
- [`DEVELOPMENT.md`](./DEVELOPMENT.md) - Development workflow
- [`STACK_MANAGEMENT.md`](./STACK_MANAGEMENT.md) - Advanced operations

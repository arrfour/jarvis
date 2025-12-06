# Jarvis Development Workflow

## Directory Structure

```
jarvis/
├── docker-compose.yaml       # Production stack
├── docker-compose.beta.yaml  # Beta/development stack (parallel)
├── .env                       # Production Tailscale auth key
├── .env.beta                  # Beta Tailscale auth key
├── nginx.conf                 # Shared Nginx config
├── compose.yaml              # (alias for docker-compose.yaml)
└── README.md
```

## Running Both Stacks in Parallel

### Production Stack (currently running)
```bash
docker compose -f docker-compose.yaml up -d
# Access: https://jarvis.tailcd013.ts.net
```

### Beta Stack (for testing new features)
```bash
docker compose -f docker-compose.beta.yaml --env-file .env.beta up -d
# Access: https://jarvis-beta.tailcd013.ts.net
```

### View Both Stacks
```bash
# All containers
docker ps

# Just production
docker compose -f docker-compose.yaml ps

# Just beta
docker compose -f docker-compose.beta.yaml ps
```

### Stop One Stack Without Affecting the Other
```bash
# Stop only beta (production keeps running)
docker compose -f docker-compose.beta.yaml down

# Stop only production (beta keeps running)
docker compose -f docker-compose.yaml down

# Stop everything
docker compose -f docker-compose.yaml down
docker compose -f docker-compose.beta.yaml down
```

## Setting Up Beta Auth Key (No More Manual Approvals)

1. **Generate new Tailscale auth key for beta:**
   - Go to https://login.tailscale.com/admin/settings/keys
   - Click "Create auth key"
   - ✅ Check "Reusable"
   - ✅ Check "Ephemeral"
   - **IMPORTANT**: Copy the key

2. **Add to `.env.beta`:**
   ```bash
   echo "TS_AUTHKEY_BETA=tskey-api-YOUR_KEY_HERE" >> .env.beta
   ```

3. **Why this works:**
   - "Reusable" = can approve multiple times without regenerating
   - "Ephemeral" = auto-removes if device goes offline for 10+ minutes
   - **Result**: Restarts don't require manual approval!

## Visual Differentiation: Beta vs Production

### What You'll See

When you access the beta instance at `https://jarvis-beta.tailcd013.ts.net`:

1. **Browser tab**: Shows **red favicon with β symbol** (vs normal icon in production)
2. **App logo**: **Red "BETA" logo** (vs production logo in production)
3. **Visual branding**: Makes it instantly obvious which version you're using

### Why This Matters

- ✅ **Prevents accidents** - won't confuse beta with production
- ✅ **Quick visual check** - look at your browser tabs, know instantly
- ✅ **User awareness** - testers know they're on experimental version
- ✅ **Zero performance impact** - just SVG images, no overhead

### Assets Location

All beta branding is in the `beta-assets/` directory:
- `favicon-beta.svg` - Red favicon with β symbol
- `logo-beta.svg` - Red "BETA" text logo
- `beta-banner.html` - Optional inline banner script

These are automatically mounted into the beta container at startup.

## Beta Data Strategy: Persistent Admin with Optional Purge

### Overview
The beta stack uses a **persistent volume** for the Open WebUI data. This means:
- ✅ Admin account persists across container restarts
- ✅ Test data (conversations, models, settings) carries over between feature iterations
- ✅ Realistic testing environment (mimics production behavior)
- ✅ Optional purge available before major releases or new features

### One-Time Setup: Create Default Beta Admin

1. **Access the beta instance:**
   - Go to https://jarvis-beta.tailcd013.ts.net
   - You'll see "Create Admin Account" prompt

2. **Create admin (first time only):**
   - Username: `admin`
   - Password: [Create something secure, save in password manager]
   - Email: admin@jarvis-beta.local

3. **After this, admin persists:**
   - Restarts won't reset credentials
   - All your test configurations save automatically

### Development Workflow with Persistent Data

```bash
# Day 1: Start beta feature branch
git checkout -b feature/my-feature
docker compose -f docker-compose.beta.yaml --env-file .env.beta up -d
# Log in with your admin account
# Test feature, create sample conversations

# Day 2: Continue work, admin still there
docker compose -f docker-compose.beta.yaml down
docker compose -f docker-compose.beta.yaml --env-file .env.beta up -d
# Admin account ready to go - no setup needed!

# Day 3: Feature complete, merge to develop
git add .
git commit -m "feat: implement my feature"
git checkout develop
git merge feature/my-feature
```

### Optional: Purge Test Data Before Release

If your test conversations and data feel "polluted" before pushing a beta version to main:

```bash
# OPTION A: Remove just the Open WebUI data (keeps Ollama models)
docker volume rm openwebuiandollama_open-webui-beta
docker compose -f docker-compose.beta.yaml --env-file .env.beta restart open-webui-beta
# Fresh start - will prompt for new admin on next access

# OPTION B: Full reset (remove everything beta-related)
docker compose -f docker-compose.beta.yaml down -v
docker compose -f docker-compose.beta.yaml --env-file .env.beta up -d
# Same as OPTION A but also clears Ollama cache
```

### When to Purge

- **Before major version release** (v2025.12.6.002) - start with clean slate
- **Between major feature areas** - if test data feels cluttered
- **Never automatically** - always a manual choice to keep control

### Key Points

✅ **Persistent state** = realistic testing (conversations, settings, API keys save)
✅ **No repeated setup** = faster iterations (admin already there)
✅ **Optional reset** = clean slate when needed (one command)
✅ **Separate from production** = zero risk of pollution
✅ **Zero bloat** = Open WebUI data stays lightweight

## Git Workflow for Beta Development

### Branch Structure
```
main (production - always stable)
  ↓
develop (beta/development work)
```

### Working on Beta Features

1. **Switch to develop branch:**
   ```bash
   git checkout develop
   ```

2. **Create a feature branch for specific work:**
   ```bash
   git checkout -b feature/eliminate-auth-approvals
   ```

3. **Make changes to beta stack:**
   - Edit `docker-compose.beta.yaml` for new features
   - Test with: `docker compose -f docker-compose.beta.yaml up -d`
   - Verify production still works

4. **Commit feature changes:**
   ```bash
   git add docker-compose.beta.yaml .env.beta
   git commit -m "feat: eliminate manual auth approvals for beta"
   ```

5. **Test thoroughly, then merge to develop:**
   ```bash
   git checkout develop
   git merge feature/eliminate-auth-approvals
   ```

6. **When ready for release, merge develop → main:**
   ```bash
   git checkout main
   git merge develop
   git tag -a v2025.12.6.002 -m "Release v2025.12.6.002: description"
   git push && git push --tags
   ```

## Container Naming Convention

| Stack | Containers | Ports | Tailscale Domain |
|-------|-----------|-------|-----------------|
| **Production** | `nginx-proxy`, `open-webui2`, `tailscale-sidecar` | 8080, 8443 | `jarvis.tailcd013.ts.net` |
| **Beta** | `nginx-beta`, `open-webui-beta`, `tailscale-sidecar-beta` | 8081 | `jarvis-beta.tailcd013.ts.net` |

## Key Points

✅ **Both stacks run independently** - no conflicts
✅ **Separate Tailscale devices** - separate hostnames on Tailnet
✅ **Reusable auth key** - beta auto-approves, no manual work
✅ **Version controlled** - track all changes in git
✅ **Safe to iterate** - production unaffected by beta experiments
✅ **Easy to test** - switch between `jarvis` and `jarvis-beta`

## Troubleshooting

**Q: How do I know if both stacks are running?**
```bash
docker ps | grep -E "nginx-|open-webui|tailscale"
```

**Q: Beta container won't start - auth key error?**
```bash
# Check beta logs
docker compose -f docker-compose.beta.yaml logs tailscale-sidecar-beta
```

**Q: I want to keep beta changes but not push to main yet?**
```bash
# Keep develop branch synced but don't merge to main
git checkout develop
git add .
git commit -m "Work in progress on beta feature"
git push origin develop
# main stays unchanged, production unaffected
```

**Q: How do I switch between testing production vs beta?**
```bash
# Test production
curl https://jarvis.tailcd013.ts.net -k

# Test beta
curl https://jarvis-beta.tailcd013.ts.net -k
```

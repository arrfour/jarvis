# Quick Start - Beta Development

## One-Time Setup

1. **Generate beta auth key** (reusable, auto-approves):
   - Go to https://login.tailscale.com/admin/settings/keys
   - Create auth key with ✓ Reusable + ✓ Ephemeral
   - Add to `beta/.env`: `TS_AUTHKEY_BETA=tskey-api-YOUR_KEY`

2. **Switch to develop branch:**
   ```bash
   git checkout develop
   ```

3. **Start beta stack:**
   ```bash
   cd beta
   docker compose up -d
   ```

4. **Create admin account** (first access only):
   - Go to https://jarvis-beta.YOUR_TAILNET.ts.net
   - Set username/password (persists across restarts!)
   - This admin account is now reusable for all beta development

## Daily Workflow

### Test Production (unchanged)
```bash
# Production keeps running normally
https://jarvis.YOUR_TAILNET.ts.net
```

### Test Beta (new features)
```bash
# Beta runs in parallel - RED UI indicates beta version
https://jarvis-beta.YOUR_TAILNET.ts.net
# Look for: Red favicon (β), red "BETA" logo
```

### Iterate on Beta Features

1. **Edit files** (e.g., `beta/docker-compose.yaml`, `beta/nginx.conf`)
2. **Restart beta stack:**
   ```bash
   cd beta
   docker compose restart
   ```
3. **Test immediately** - admin account still there, no relogin needed!
4. **No certificate warnings** - Tailscale handles it automatically

### Data Persistence

- Admin account persists across restarts
- Test conversations and configurations save automatically
- Each feature iteration keeps the same data (realistic testing)
- To start fresh before a release: `docker volume rm jarvis_open-webui-beta`

## Committing Changes

```bash
# Make sure you're on develop
git branch  # Should show "* develop"

# Stage changes
git add beta/docker-compose.yaml beta/nginx.conf

# Commit with descriptive message
git commit -m "feat: update beta feature X"

# Push to GitHub
git push
```

## When Beta is Ready for Release

```bash
# Switch to main (production)
git checkout main

# Merge beta work
git merge develop

# Tag the release
git tag -a v2025.12.6.002 -m "Release description"

# Push everything
git push && git push --tags

# Update production
docker compose down
git pull
docker compose up -d
```

## Why This Works

✅ **Reusable auth key** - Auto-approves beta device, no manual clicks
✅ **Separate Tailscale hostname** - `jarvis` vs `jarvis-beta`
✅ **Parallel containers** - Production unaffected by beta testing
✅ **Version controlled** - All changes tracked in git
✅ **Safe iteration** - Break things in beta, production stays stable

## Important Notes

- Production (main branch) should always be stable
- Beta (develop branch) is for experiments & new features
- Use feature branches for specific work: `git checkout -b feature/your-feature`
- Only merge to main when beta is thoroughly tested
- Both auth keys expire if unused—regenerate if needed

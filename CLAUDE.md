# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Jarvis** is a containerized deployment of Open WebUI (LLM chat interface) + Ollama (local LLM runtime) accessible via Tailscale's end-to-end encrypted private network with automatic valid HTTPS certificates.

Key features:
- **Dual-stack architecture**: Production (stable) + Beta (latest features) running independently
- **Tailscale integration**: No port forwarding, encrypted private network access, valid certificates
- **Multiple management interfaces**: bash CLI (`manage.sh`), interactive TUI (`tui.sh`), or Ansible
- **GPU support**: Auto-detects NVIDIA/AMD GPUs (NVIDIA/AMD compose file overrides)
- **Persistent volumes**: Models and data persist across container restarts

## High-Level Architecture

### Stack Structure

Both production and beta stacks follow this pattern:

```
Stack = Open WebUI Container + Tailscale Sidecar + Nginx Reverse Proxy
```

**Production Stack** (stable, pinned version):
- Open WebUI: `ghcr.io/open-webui/open-webui:v0.7.2-ollama` (pinned for reliability)
- Tailscale hostname: `jarvis`
- Ports: 8080 (Nginx), 11434 (Ollama API)
- Access: `https://jarvis.YOUR_TAILNET.ts.net`

**Beta Stack** (testing, rolling tag):
- Open WebUI: `ghcr.io/open-webui/open-webui:main-ollama` (latest features)
- Tailscale hostname: `jarvis-beta`
- Ports: 8081 (Nginx), 11435 (Ollama API)
- Access: `https://jarvis-beta.YOUR_TAILNET.ts.net`
- Visual branding: Red favicon + logo (assets in `beta/assets/`)

### Networking & Storage

**Networks**: Each stack has isolated Docker bridge networks (`internal-prod`, `internal-beta`)
**Volumes**:
- Production: `ollama`, `open-webui`, `tailscale-sidecar-state`
- Beta: `ollama-beta`, `open-webui-beta`, `tailscale-sidecar-beta-state`

All container communication happens on Docker internal networks. Only Nginx (through Tailscale) is exposed externally.

### Docker Compose Profiles

Root `docker-compose.yaml` uses profiles to manage both stacks:
- `--profile all`: Both stacks (default)
- `--profile prod`: Production only
- `--profile beta`: Beta only

Profiles enable one config file to manage multiple independent stacks without conflicts.

## Common Development Tasks

### Starting/Stopping Stacks

**Option 1: Bash CLI (Recommended)**
```bash
./manage.sh start              # Start both stacks
./manage.sh start-prod         # Production only
./manage.sh start-beta         # Beta only
./manage.sh stop               # Stop both
./manage.sh restart-prod       # Restart production
./manage.sh help               # See all commands
```

**Option 2: Interactive TUI**
```bash
./manage.sh                    # Launches TUI automatically
# or
./tui.sh                       # Direct launch
# Requires: sudo apt install dialog (first time)
```

**Option 3: Ansible**
```bash
cd ansible
make install                   # One-time setup
make start                     # Start both stacks
make restart-beta              # Restart beta only
make status                    # Check status
make help                      # See all commands
```

### Monitoring & Logs

```bash
./manage.sh logs               # All logs
./manage.sh logs-prod          # Production only
./manage.sh logs-beta          # Beta only
./manage.sh status             # Container health
docker stats                   # Real-time resource usage
```

### Working with Containers Directly

```bash
# Shell into production Open WebUI
docker exec -it open-webui2 bash

# Check Tailscale status
docker exec tailscale-sidecar tailscale status

# Manage Ollama models (production)
docker exec -it open-webui2 ollama list
docker exec -it open-webui2 ollama pull llama2

# View Nginx configuration (production)
docker exec nginx-proxy cat /etc/nginx/nginx.conf
```

### Volume Management

```bash
# List all Jarvis volumes
docker volume ls | grep jarvis

# Inspect a volume's mount point
docker volume inspect jarvis_ollama

# Remove beta Open WebUI data (keeps Ollama models)
docker volume rm jarvis_open-webui-beta

# Full beta reset (removes everything)
docker compose --profile beta down -v
docker compose --profile beta up -d
```

## Key Concepts & Design Patterns

### 1. Tailscale Integration

- **Auth keys stored in `.env` files**: `production/.env` and `beta/.env` (gitignored)
- **Sidecar approach**: Tailscale runs as a sidecar container, not embedded in Open WebUI
- **Privileged mode**: Sidecar containers run privileged to manage TUN devices and routing
- **Automatic certificate management**: Tailscale Serve provides valid HTTPS certs on your Tailnet domain
- **Key rotation**: Keys expire after 90 days and should be rotated periodically

### 2. Dual-Stack Parallel Operation

- Production and beta are **completely independent** - no resource conflicts
- **Separate Tailscale devices** - appear as different nodes on Tailnet (`jarvis` vs `jarvis-beta`)
- **Persistent data per stack** - beta can run side-by-side with production in testing
- **Same machine can run both** - different ports, networks, and volumes

### 3. Version Strategy

**Production**: Pinned to specific stable version (e.g., `v0.7.2-ollama`)
- Reason: Reliability, no surprise breaking changes
- Update: Manual version bump in `docker-compose.yaml`

**Beta**: Rolling `main` tag, always latest
- Reason: Test bleeding-edge features before release
- Risk: May contain bugs or incomplete features

### 4. Nginx as Reverse Proxy

Each stack has dedicated `nginx.conf`:
- Routes HTTP traffic from port 8080/8081 to Open WebUI container
- Sets proper headers (`X-Forwarded-*`, `Host`)
- Handles static asset serving for beta branding

### 5. Environment Variable Loading

In `manage.sh` and other scripts:
```bash
set -a
[ -f "production/.env" ] && source "production/.env"
set +a
```
This pattern (not using `xargs`) prevents shell injection if secrets contain spaces/metacharacters.

## File Structure Quick Reference

```
jarvis/
├── docker-compose.yaml          # Root unified config (both stacks)
├── docker-compose.nvidia.yaml   # GPU override for NVIDIA
├── docker-compose.amd.yaml      # GPU override for AMD
├── manage.sh                    # Bash CLI management tool
├── tui.sh                       # Interactive TUI (requires dialog)
│
├── production/
│   ├── docker-compose.yaml      # Production-specific overrides
│   ├── nginx.conf               # Production Nginx config
│   ├── .env                     # Tailscale auth key (gitignored)
│   └── .env.example             # Template
│
├── beta/
│   ├── docker-compose.yaml      # Beta-specific overrides
│   ├── nginx.conf               # Beta Nginx config
│   ├── tailscale-entrypoint.sh  # Custom Tailscale startup (beta)
│   ├── assets/                  # Red branding (favicon, logo)
│   ├── .env                     # Tailscale auth key (gitignored)
│   └── .env.example             # Template
│
├── ansible/
│   ├── Makefile                 # Convenient shortcuts (make start, etc.)
│   ├── playbooks/
│   │   ├── site.yml             # Main playbook with all tags
│   │   ├── start.yml            # Shortcut for start
│   │   ├── stop.yml             # Shortcut for stop
│   │   ├── restart.yml          # Shortcut for restart
│   │   └── status.yml           # Shortcut for status
│   ├── roles/
│   │   ├── setup/               # Install Docker/Tailscale deps
│   │   ├── environment/         # Configure .env files
│   │   └── stack/               # Deploy/manage containers
│   └── requirements.yml         # Ansible Galaxy dependencies
│
├── README.md                    # Main overview
├── DEVELOPMENT.md               # Dev workflow & git practices
├── DEPLOYMENT.md                # Portability & Linux deployment
├── SECURITY.md                  # Security considerations
├── TROUBLESHOOTING.md           # Common issues & fixes
├── STACK_MANAGEMENT.md          # Manual Docker operations
├── BETA_QUICKSTART.md           # Daily beta testing checklist
└── ANSIBLE_MIGRATION.md         # Migration from bash to Ansible
```

## Security Considerations

### Secrets Management

- **Auth keys are gitignored**: Never commit `.env` files containing `TS_AUTHKEY`
- **Immediate rotation on leak**: If accidentally committed, rotate immediately at https://login.tailscale.com/admin/settings/keys
- **Separate keys**: Use different auth keys for production and beta
- **Ephemeral + Reusable**: Keys created with both flags auto-approve and auto-remove if offline >10 min

### Network Exposure

Current configuration binds to `0.0.0.0:8080` and `0.0.0.0:8081`, making HTTP accessible on the LAN. To restrict to Tailscale-only, change to `127.0.0.1` in `docker-compose.yaml` (Tailscale still works through sidecar).

### CORS Configuration

Open WebUI logs a warning: `CORS_ALLOW_ORIGIN IS SET TO '*'`. For production with known clients, consider setting specific origins in environment variables.

## Important Patterns & Conventions

### Branch Strategy

- `main`: Production-stable, tagged releases (e.g., `v2025.12.6.001`)
- `develop`: Beta/development work, feature branches off this
- Feature branches: `feature/*` (e.g., `feature/tailscale-optimization`)

### Commit Message Style

See `DEVELOPMENT.md` for git practices. Generally:
- Feat: new feature
- Fix: bug fix
- Refactor: code restructure
- Docs: documentation
- Keep messages concise and purpose-focused

### Resource Management

**Logging**: All containers use `json-file` driver with rotation:
- Max size: 10MB per file
- Max files: 3 per container
- Prevents disk bloat from long-running deployments

**GPU Support**:
- NVIDIA: `docker-compose.nvidia.yaml` override (automatically used if detected)
- AMD: `docker-compose.amd.yaml` override (automatically used if detected)
- Force CPU-only: `./manage.sh start --cpu`

## Troubleshooting Quick Checks

1. **Containers won't start?**
   ```bash
   ./manage.sh logs      # Check all logs
   docker ps            # Verify containers exist
   ```

2. **HTTPS connection fails?**
   - Verify device approved in Tailscale admin: https://login.tailscale.com/admin/machines
   - Check Tailscale status: `docker exec tailscale-sidecar tailscale status`

3. **Too many restarts causing rate limits?**
   - Certbot/Let's Encrypt may be hitting rate limits
   - Check logs: `./manage.sh logs-prod` or `./manage.sh logs-beta`
   - Wait before restarting (rate limit recovery takes time)

4. **Models not persisting?**
   - Check volume: `docker volume inspect jarvis_ollama`
   - Verify mount in container: `docker inspect open-webui2`

5. **CORS or proxy issues?**
   - Check Nginx config: `docker exec nginx-proxy cat /etc/nginx/nginx.conf`
   - Restart Nginx: `docker restart nginx-proxy`

## Testing Beta Features

Beta testing workflow:

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes, test locally: `./manage.sh start-beta`
3. Test at `https://jarvis-beta.YOUR_TAILNET.ts.net` (red branding confirms beta)
4. Optional purge of test data: `docker volume rm jarvis_open-webui-beta`
5. Merge to main when ready: `git checkout main && git merge feature/my-feature`

## Performance Tips

1. **GPU allocation**: Automatically detected; use `--cpu` flag to force CPU-only
2. **Model persistence**: Ollama models stored in volumes, survives restarts
3. **Memory intensive**: Both Open WebUI + Ollama can consume significant RAM
4. **Monitor usage**: `docker stats` shows real-time CPU/memory per container

## References

- [Tailscale Docs](https://tailscale.com/kb)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Open WebUI GitHub](https://github.com/open-webui/open-webui)
- [Ollama Documentation](https://ollama.ai)
- [Nginx Documentation](https://nginx.org/en/docs/)

# Jarvis - Open WebUI on Tailscale

A dual-stack (production + beta) containerized deployment of **Open WebUI** with **Ollama** support, securely accessible via **Tailscale** with automatically-issued valid HTTPS certificates. No port forwarding. No self-signed warnings. Pure private network security.

**Current Version:** `v1.1.0` - Security Hardening & Stability Release

## ✨ Features

- 🤖 **Open WebUI** - Modern web interface for LLM chat and interactions
- 🧠 **Ollama Backend** - Local LLM runtime with persistent models
- 🔐 **Tailscale Integration** - End-to-end encrypted private network (no port forwarding needed)
- ✅ **Valid HTTPS Certificates** - Automatic certs via Tailscale Serve (zero warnings)
- 🔄 **Dual-Stack Architecture** - Production and beta environments running independently
- 🎨 **Visual Differentiation** - Beta marked with red branding for quick identification
- 📦 **Docker Compose** - Reproducible, version-controlled infrastructure
- 🛠️ **Interactive TUI** - Beautiful terminal interface with keyboard navigation
- 🎛️ **Ansible Automation** - Enterprise-grade declarative operations
- 🛡️ **Security Hardened** - 12 critical security & stability improvements in v1.1.0

## 🚀 What's New in v1.1.0

**Security Hardening Release** with comprehensive improvements:

### 🔒 Security Enhancements
- **Security Headers** - HTTP headers added (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection) to prevent clickjacking and injection attacks
- **Pinned Dependencies** - Tailscale Docker image pinned to stable version `v1.72.0` (eliminates surprise breaking changes)
- **Safe Configuration Parsing** - Robust YAML parsing prevents injection vulnerabilities in image version detection

### 🛡️ Stability & Resource Management
- **Resource Limits** - CPU (4 cores) and memory (8GB) limits enforced per container to prevent OOM crashes
- **Robust Error Handling** - Error traps with line-number reporting for faster diagnostics
- **Improved Container Detection** - Fixed race conditions in Tailscale readiness checks

### 🔧 Operational Improvements
- **Consistent Networking** - Production and beta stacks now use identical network modes for reliability
- **Dynamic Volume Management** - Stack destruction now safely handles volumes even if project directory is renamed
- **Better TUI Feedback** - Dialog now distinguishes between user cancellations and actual errors
- **Optimized Log Parsing** - Robust image tag parsing prevents configuration errors from YAML format changes

### ⚡ Performance Optimizations
- **TUI Cleanup** - Removed unnecessary temporary file operations (faster startup)
- **Consistent Tailscale Configuration** - Both prod and beta use identical HTTPS/HTTP proxying syntax

## 🏗️ Architecture

```
jarvis/
├── 📋 Core Management
│   ├── docker-compose.yaml          ← Root unified orchestration
│   ├── docker-compose.nvidia.yaml   ← GPU override (NVIDIA)
│   ├── docker-compose.amd.yaml      ← GPU override (AMD)
│   ├── tui.sh                       ← Interactive TUI (recommended)
│   ├── manage.sh                    ← CLI tool + TUI launcher
│   └── .gitignore                   ← Secrets protection
│
├── 🐳 Docker Stack Configurations
│   ├── production/                  ← Production stack (pinned versions)
│   │   ├── docker-compose.yaml      ← Prod-specific overrides
│   │   ├── nginx.conf               ← Reverse proxy config
│   │   ├── README.md                ← Prod documentation
│   │   └── .env.example             ← Template for auth keys
│   │
│   └── beta/                        ← Beta stack (latest features)
│       ├── docker-compose.yaml      ← Beta-specific overrides
│       ├── nginx.conf               ← Reverse proxy config
│       ├── tailscale-entrypoint.sh  ← Custom Tailscale startup
│       ├── assets/                  ← Red branding (favicon + logo)
│       ├── README.md                ← Beta documentation
│       └── .env.example             ← Template for auth keys
│
├── 🤖 Ansible Automation (Optional)
│   ├── README.md                    ← Ansible setup guide
│   ├── IMPLEMENTATION.md            ← Technical details
│   ├── Makefile                     ← Easy command interface
│   ├── quickstart.sh                ← One-command deployment
│   ├── ansible.cfg                  ← Ansible configuration
│   ├── playbooks/                   ← Start/stop/status/restart
│   └── roles/                       ← Setup, environment, stack
│
└── 📚 Documentation
    ├── README.md                    ← Main overview (you are here!)
    ├── USER_GUIDE.md                ← User-facing guide for chat access
    ├── CLAUDE.md                    ← Project instructions for Claude Code
    ├── DEPLOYMENT.md                ← Server deployment guide
    ├── DEVELOPMENT.md               ← Dev workflow & git practices
    ├── TROUBLESHOOTING.md           ← Common issues and fixes
    ├── STACK_MANAGEMENT.md          ← Manual Docker operations
    ├── BETA_QUICKSTART.md           ← Beta testing checklist
    └── ANSIBLE_MIGRATION.md         ← Ansible workflow guide
```

## 🚀 Quick Start

### Prerequisites

- **Docker & Docker Compose** - v2.0+
- **Tailscale Account** - Free at https://tailscale.com
- **Tailscale Auth Keys** - Generate 2 (one for prod, one for beta)
  - Go to: https://login.tailscale.com/admin/settings/keys
  - Create with **Reusable** + **Ephemeral** options enabled

### Initial Setup (5 minutes)

**1. Clone/extract the repository**
```bash
cd /path/to/jarvis
```

**2. Add your Tailscale auth keys**
```bash
cp production/.env.example production/.env
cp beta/.env.example beta/.env

# Edit both files with your auth keys
nano production/.env      # Add TS_AUTHKEY=tskey-auth-xxxxx
nano beta/.env            # Add TS_AUTHKEY_BETA=tskey-auth-yyyyy
```

**3. Start everything**
```bash
./manage.sh start
```

**4. Access your stacks**
- **Production:** `https://jarvis.YOUR_TAILNET.ts.net`
- **Beta:** `https://jarvis-beta.YOUR_TAILNET.ts.net` (red branding)
- **Local HTTP:** `http://localhost:8080` (prod), `http://localhost:8081` (beta)

Done! Both stacks are now running.

## 📋 Stack Management

You have **three options** for managing stacks:

### Option 1: Interactive TUI (Recommended)

Beautiful keyboard-driven interface with status dashboard:

```bash
# Install dialog (one-time)
sudo apt install dialog     # Debian/Ubuntu
sudo dnf install dialog     # Fedora

# Launch TUI
./manage.sh                 # Auto-launches when no args
./tui.sh                    # Direct TUI launch
```

**Features:**
- 🎹 Keyboard navigation (arrow keys + Enter)
- 📊 Real-time status dashboard with health icons
- 📋 Live log streaming
- ⚠️ Confirmation dialogs for destructive operations

### Option 2: CLI Commands (Quick & Simple)

Direct command execution without TUI:

```bash
./manage.sh start          # Start both stacks
./manage.sh restart-beta   # Restart beta only
./manage.sh logs-prod      # View production logs
./manage.sh help           # Show all commands
```

### Option 3: Ansible (Infrastructure as Code)

For idempotent, declarative operations:

```bash
cd ansible
make install               # One-time setup
make start                 # Start both stacks
make restart-beta          # Restart beta only
make status                # Check status
```

See [ansible/README.md](ansible/README.md) for full Ansible documentation.

## 📊 Common Tasks

### Check stack health
```bash
./manage.sh status
```

### View logs
```bash
./manage.sh logs          # All stacks
./manage.sh logs-prod     # Production only
./manage.sh logs-beta     # Beta only
```

### Update a model in Ollama
```bash
docker exec -it open-webui2 ollama pull llama2
docker exec -it open-webui-beta ollama pull mistral
```

### Stop all stacks
```bash
./manage.sh stop
```

## 🌍 Access from Outside Your Machine

Since everything runs on Tailscale, you can access it from **any device on your Tailnet**:

1. **From another Linux box:**
   ```bash
   curl https://jarvis.YOUR_TAILNET.ts.net
   ```

2. **From Windows/Mac with Tailscale installed:**
   - Open browser: `https://jarvis.YOUR_TAILNET.ts.net`
   - Works exactly like localhost but encrypted end-to-end

3. **From mobile (iOS/Android Tailscale app):**
   - Install Tailscale app
   - Same FQDN works

## 🐳 Docker Compose Profiles

The root `docker-compose.yaml` uses **profiles** to manage multiple stacks:

```bash
docker-compose --profile all up -d    # Both prod + beta
docker-compose --profile prod up -d   # Production only
docker-compose --profile beta up -d   # Beta only
```

Use `manage.sh` to avoid remembering these flags.

## 📚 Documentation

- **[USER_GUIDE.md](./USER_GUIDE.md)** - For end users accessing JARVIS
- **[CLAUDE.md](./CLAUDE.md)** - Project overview and architecture for developers
- **[DEVELOPMENT.md](./DEVELOPMENT.md)** - Development workflow and git practices
- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Deploy to remote Linux servers
- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Common issues and fixes
- **[STACK_MANAGEMENT.md](./STACK_MANAGEMENT.md)** - Deep dive into manual operations
- **[ansible/README.md](./ansible/README.md)** - Ansible automation guide

## 🚀 Performance Tips

1. **GPU Support**: Automatically detected (NVIDIA or AMD)
   - Use `./manage.sh start --cpu` to force CPU-only mode

2. **Model Management**: Ollama models stored in persistent volumes
   - Production: `docker volume inspect jarvis_ollama`
   - Beta: `docker volume inspect jarvis_ollama-beta`

3. **Memory**: Monitor with `docker stats`

## 🔐 Security Notes

- ✅ All traffic encrypted (Tailscale VPN + HTTPS)
- ✅ No port forwarding needed
- ✅ Valid certificates (no self-signed warnings)
- ✅ Auth keys expire and auto-approve (90 days)
- ✅ Hardened with security headers (XSS, clickjacking protection)

**Best Practices:**
1. Regenerate auth keys periodically
2. Keep Tailscale updated
3. Review connected devices: https://login.tailscale.com/admin/machines
4. Use separate keys for prod and beta

## 📝 Version Control

This repo tracks:
- ✅ Configuration files (docker-compose.yaml, nginx.conf)
- ✅ Deployment scripts (manage.sh, tui.sh)
- ✅ Documentation
- ❌ `.env` files (gitignored - contains secrets)
- ❌ Volumes/data (handled by Docker)

**Current Release:**
- **Version**: v1.1.0 (Security Hardening & Stability Release)
- **Branch**: `main` (production-stable)
- **Previous**: v2025.12.6.003

View all releases: `git tag -l | sort -V`

## 🆘 Troubleshooting

**Issue:** Can't connect to `jarvis.YOUR_TAILNET.ts.net`
- Verify device is approved in Tailscale admin
- Check: `./manage.sh status`
- View logs: `./manage.sh logs`

**Issue:** Models not persisting?
```bash
docker volume ls | grep jarvis
docker volume inspect jarvis_ollama
```

**Issue:** Slow responses?
- Try a smaller model
- Check GPU is being used: `./manage.sh monitor-gpu`

**More issues?** See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

## 🎓 Learning Resources

- [Tailscale Documentation](https://tailscale.com/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Open WebUI GitHub](https://github.com/open-webui/open-webui)
- [Ollama Documentation](https://ollama.ai)

## 📄 License

MIT License - Feel free to use, modify, and share

## 📝 Changelog

- **v1.1.0** - Security hardening: 12 critical improvements (headers, pinned deps, resource limits, error handling, etc.)
- **v2025.12.6.003** - Code review remediations
- **v2025.12.6.002** - Fixed logging and cert rotation
- **v2025.12.6.001** - Initial release with Tailscale HTTPS certificates

---

Found a bug or have an improvement? Submit a pull request or open an issue on GitHub.

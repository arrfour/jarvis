# Jarvis - Open WebUI on Tailscale

A dual-stack (production + beta) containerized deployment of **Open WebUI** with **Ollama** support, securely accessible via **Tailscale** with automatically-issued valid HTTPS certificates. No port forwarding. No self-signed warnings. Pure private network security.

## ✨ Features

- 🤖 **Open WebUI** - Modern web interface for LLM chat and interactions
- 🧠 **Ollama Backend** - Local LLM runtime with persistent models
- 🔐 **Tailscale Integration** - End-to-end encrypted private network (no port forwarding needed)
- ✅ **Valid HTTPS Certificates** - Automatic Let's Encrypt certs via Tailscale Serve (zero warnings)
- 🔄 **Dual-Stack Architecture** - Production and beta environments running independently
- 🎨 **Visual Differentiation** - Beta marked with red branding for quick identification
- 📦 **Docker Compose** - Reproducible, version-controlled infrastructure
- 🛠️ **Easy Management** - Bash `manage.sh` script OR Ansible automation for enterprise deployments
- 🚀 **Ansible Automation** - One-command deployment to remote Linux servers with `make deploy`

## 🏗️ Architecture

```
jarvis/
├── 📋 Configuration & Management
│   ├── docker-compose.yaml          ← Root unified orchestration (both stacks)
│   ├── manage.sh                    ← Bash CLI tool (legacy, still supported)
│   ├── .env                         ← Root environment template
│   ├── .gitignore                   ← Secrets protection
│   └── certs/                       ← SSL certificates (auto-generated)
│
├── 🤖 Ansible Automation (Recommended for deployments)
│   ├── ansible/
│   │   ├── README.md                ← Ansible setup and usage guide
│   │   ├── IMPLEMENTATION.md        ← Technical implementation details
│   │   ├── Makefile                 ← Easy command interface (make deploy, etc.)
│   │   ├── quickstart.sh            ← One-command deployment script
│   │   ├── requirements.yml         ← Ansible dependencies
│   │   ├── ansible.cfg              ← Ansible configuration
│   │   ├── inventory/
│   │   │   └── hosts.yml            ← Target hosts configuration
│   │   ├── playbooks/
│   │   │   ├── site.yml             ← Master playbook (calls all roles)
│   │   │   ├── start.yml            ← Start stacks
│   │   │   ├── stop.yml             ← Stop stacks
│   │   │   ├── restart.yml          ← Restart stacks
│   │   │   └── status.yml           ← Check stack status
│   │   └── roles/
│   │       ├── setup/               ← Install Docker, Tailscale dependencies
│   │       ├── environment/         ← Configure .env files
│   │       └── stack/               ← Deploy and manage stacks
│   │
│   └── ANSIBLE_MIGRATION.md         ← Guide for adopting Ansible workflow
│
├── 🐳 Docker Stack Configurations
│   ├── production/                  ← Production stack (main deployment)
│   │   ├── docker-compose.yaml      ← Compose file for production
│   │   ├── nginx.conf               ← Nginx reverse proxy config
│   │   ├── README.md                ← Production-specific docs
│   │   ├── .env                     ← Production auth key (gitignored)
│   │   └── .env.example             ← Template for setup
│   │
│   ├── beta/                        ← Beta stack (testing/development)
│   │   ├── docker-compose.yaml      ← Compose file for beta
│   │   ├── nginx.conf               ← Nginx reverse proxy config
│   │   ├── README.md                ← Beta-specific docs
│   │   ├── assets/                  ← Red branding (favicon + logo)
│   │   ├── .env                     ← Beta auth key (gitignored)
│   │   └── .env.example             ← Template for setup
│   │
│   └── shared/                      ← Shared resources (future use)
│
└── 📚 Documentation
    ├── README.md                    ← Main overview (you are here!)
    ├── DEPLOYMENT.md                ← Portability & Linux server deployment
    ├── TROUBLESHOOTING.md           ← Common issues and fixes
    ├── DEVELOPMENT.md               ← Development workflow & git practices
    ├── STACK_MANAGEMENT.md          ← Deep dive into manual operations
    ├── BETA_QUICKSTART.md           ← Daily beta testing checklist
    └── ANSIBLE_MIGRATION.md         ← Migration from bash to Ansible
```

### 🎯 Quick Navigation

| Need to... | Start here |
|-----------|-----------|
| **Deploy to new server** | `ansible/README.md` → `bash quickstart.sh` |
| **Manage locally (WSL/Linux)** | `./manage.sh help` (bash CLI) |
| **Troubleshoot issues** | `TROUBLESHOOTING.md` |
| **Develop new features** | `DEVELOPMENT.md` |
| **Deploy production** | `DEPLOYMENT.md` or `ansible/Makefile` |
| **Understand architecture** | This section + `ANSIBLE_MIGRATION.md` |
| **Run beta tests** | `BETA_QUICKSTART.md` |

## 🚀 Quick Start

### Prerequisites

- **Docker & Docker Compose** - v2.0+
- **Tailscale Account** - Free at https://tailscale.com
- **Tailscale Auth Keys** - Generate 2 (one for prod, one for beta)
  - Go to: https://login.tailscale.com/admin/settings/keys
  - Create with **Reusable** + **Ephemeral** options enabled
  - Auto-approves devices for 90 days

### Initial Setup (5 minutes)

**1. Clone or extract the repository**
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
- **Production:** `https://jarvis.YOUR_TAILNET.ts.net` (replace `YOUR_TAILNET` with your actual Tailnet name)
- **Beta:** `https://jarvis-beta.YOUR_TAILNET.ts.net` (red branding)
- **Local HTTP:** `http://localhost:8080` (prod), `http://localhost:8081` (beta)

Done! Both stacks are now running.

## 📋 Stack Management

You have **two options** for managing stacks:

### Option 1: Bash Script (Quick & Simple)

The `manage.sh` script provides quick, intuitive commands:

```bash
./manage.sh start          # Start both stacks
./manage.sh restart-beta   # Restart beta only
./manage.sh logs-prod      # View production logs
./manage.sh help           # Show all commands
```

### Option 2: Ansible (Infrastructure as Code)

For idempotent, declarative operations:

```bash
cd ansible
make install               # One-time setup
make start                 # Start both stacks
make restart-beta          # Restart beta only
make status                # Check status
```

See [ansible/README.md](ansible/README.md) for full Ansible documentation.

**Both approaches work side-by-side** - use whichever fits your workflow!

### The `manage.sh` Command Reference

**Recommended for quick operations.**

### Start/Stop Commands

```bash
./manage.sh start              # 🚀 Start both production and beta
./manage.sh start-prod         # 🚀 Start only production
./manage.sh start-beta         # 🚀 Start only beta
./manage.sh stop               # 🛑 Stop both stacks
./manage.sh stop-prod          # 🛑 Stop only production
./manage.sh stop-beta          # 🛑 Stop only beta
```

### Restart Commands

## 🎯 Real-World Workflows

### Scenario 1: Testing a Feature in Beta

1. Code changes go to `develop` branch
2. Deploy to beta stack: `./manage.sh start-beta`
3. Test at `https://jarvis-beta.YOUR_TAILNET.ts.net` (red branding = you know it's beta)
4. Review changes: `git diff main develop`
5. Merge to main when ready: Create PR or `git merge develop`
6. Deploy to prod: `./manage.sh restart-prod`

### Scenario 2: Emergency Rollback

```bash
# View all versions
git tag -l | sort -V

# Rollback to specific version
git checkout v2025.12.6.002
./manage.sh start-prod

# Or return to current
git checkout main
./manage.sh start-prod
```

### Scenario 3: Updating Ollama Models

```bash
# Connect to Ollama in production
docker exec -it ollama ollama list          # See installed models
docker exec -it ollama ollama pull llama2   # Download new model

# Same for beta
docker exec -it ollama-beta ollama pull mistral
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
   - Enable "Allow incoming connections"
   - Same FQDN works

## 🐳 Docker Compose Profiles Explained

The root `docker-compose.yaml` uses **profiles** to run multiple stacks:

```bash
# Start both (prod + beta)
docker-compose --profile all up -d

# Start only production
docker-compose --profile prod up -d

# Start only beta
docker-compose --profile beta up -d
```

**Why profiles?** Allows one file to manage multiple independent stacks without conflicts.

Use `manage.sh` to avoid remembering these flags.

## 🔄 Environment Variables

### Production (`.env` in `production/` directory)
```bash
TS_AUTHKEY=tskey-auth-xxxxxxxxx    # Tailscale auth key for prod
```

### Beta (`.env` in `beta/` directory)
```bash
TS_AUTHKEY_BETA=tskey-auth-yyyyy    # Tailscale auth key for beta
```

Both are **gitignored** (never committed). Template versions (`.env.example`) are in git for reference.

## 📚 Documentation

**Choose your path:**

### 🚀 New Deployments (Recommended: Ansible)
- [`ansible/README.md`](./ansible/README.md) - **Deploy to remote Linux servers** - Ansible automation guide
- [`ANSIBLE_MIGRATION.md`](./ANSIBLE_MIGRATION.md) - Migration guide from bash to Ansible

### 💻 Local Development (Bash CLI)
- [`README.md`](./README.md) - **Overview and quick start** (you're reading it)
- [`DEVELOPMENT.md`](./DEVELOPMENT.md) - Development workflow and git practices
- [`BETA_QUICKSTART.md`](./BETA_QUICKSTART.md) - Daily beta testing checklist

### 📖 Reference & Operations
- [`DEPLOYMENT.md`](./DEPLOYMENT.md) - Portability guide and manual Linux deployment
- [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) - Common issues and fixes
- [`STACK_MANAGEMENT.md`](./STACK_MANAGEMENT.md) - Deep dive into manual Docker operations

## 🆘 Troubleshooting

### HTTPS not working?
See [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md#https-access-not-working)

### Containers won't start?
```bash
./manage.sh logs      # Check all logs
./manage.sh status    # Check container status
```

### Models not persisting?
Check volume mounts:
```bash
docker volume ls | grep jarvis
docker volume inspect jarvis_ollama
```

### Serve configuration lost after restart?
Restart handles this automatically:
```bash
./manage.sh restart-prod
```

## 🛠️ Manual Docker Commands (Advanced)

For power users who want direct control:

```bash
# Direct Compose commands (from root directory)
docker-compose --profile prod config          # Show prod config
docker-compose --profile prod logs -f         # Follow prod logs
docker-compose --profile prod restart         # Restart prod

# Direct service access
docker exec open-webui2 bash                  # Shell into production Open WebUI
docker exec tailscale-sidecar tailscale status   # Check Tailscale status
```

## 📊 Monitoring

### Check stack health
```bash
./manage.sh status
```

### View real-time logs
```bash
./manage.sh logs          # All
./manage.sh logs-prod     # Production only
./manage.sh logs-beta     # Beta only
```

### Validate configuration
```bash
./manage.sh validate
```

This checks syntax without starting containers.

## 🚀 Performance Tips

1. **GPU Support**: Both stacks have `gpus: all` enabled. Works on NVIDIA only.
   - Remove from `docker-compose.yaml` if you don't have GPU

2. **Model Management**: Ollama models stored in persistent volumes
   - Production models: `docker volume inspect jarvis_ollama`
   - Beta models: `docker volume inspect jarvis_ollama-beta`

3. **Memory**: Open WebUI + Ollama can be resource-intensive
   - Monitor with: `docker stats`

## 🔐 Security Notes

- ✅ All traffic encrypted (Tailscale VPN + Tailscale Serve HTTPS)
- ✅ No port forwarding needed
- ✅ Valid certificates (no self-signed warnings)
- ✅ Auth keys expire and auto-approve (90 days)
- ✅ Tailnet-only access (private network)

**Best Practices:**
1. Regenerate auth keys periodically
2. Keep Tailscale updated: `tailscale update`
3. Review connected devices: https://login.tailscale.com/admin/machines
4. Use separate keys for prod and beta

## 📝 Version Control

This repo tracks:
- ✅ Configuration files (docker-compose.yaml, nginx.conf)
- ✅ Deployment scripts (manage.sh)
- ✅ Documentation
- ❌ `.env` files (gitignored - contains secrets)
- ❌ Volumes/data (handled by Docker)

### Current Release
- **Version**: v2025.12.6.003 (tagged in git)
- **Branch**: `main` (production-stable)
- **Development**: `develop` branch

View all releases: `git tag -l | sort -V`

## 🎓 Learning Resources

- [Tailscale Documentation](https://tailscale.com/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Open WebUI GitHub](https://github.com/open-webui/open-webui)
- [Ollama Documentation](https://ollama.ai)

## 📞 Support

Having issues?
1. Check [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md)
2. Run `./manage.sh logs` to see what's happening
3. Search GitHub issues: https://github.com/open-webui/open-webui/issues

## 🆘 Troubleshooting

### Device won't approve in Tailscale Admin
- Verify auth key is valid and reusable
- Check Tailscale logs: `docker compose logs tailscale-sidecar`
- Wait a few seconds and refresh the admin panel

### Can't connect to `jarvis.YOUR_TAILNET.ts.net`
- Try the direct IP: `https://100.x.x.x:8443`
- Verify device is approved in Tailscale admin
- Clear browser cookies and try again
- Check: `docker compose ps` (all containers should be running)

### ERR_TOO_MANY_REDIRECTS
- Clear browser cookies for the domain
- Restart Nginx: `docker compose restart nginx`

### 502 Bad Gateway
- Check Open WebUI is healthy: `docker compose ps`
- View Nginx logs: `docker compose logs nginx`
### SSL Certificate Warnings

**There should be none!** Tailscale provides valid HTTPS certificates automatically on your Tailnet domain. Access `https://jarvis.YOUR_TAILNET.ts.net` and your browser should trust the certificate immediately.
- Click "Advanced" → "Proceed" in your browser
- To avoid warnings, use a valid certificate from Let's Encrypt (requires public domain)

## 🚀 Scaling - Adding More Services

1. Add service to `compose.yaml` on the `internal` network
2. Update `nginx.conf` with a new location block:
   ```nginx
   location /service-path/ {
       proxy_pass http://service-name:port/;
       proxy_set_header Host $host;
       proxy_set_header X-Forwarded-Proto $scheme;
       # ... other headers
   }
   ```
3. Restart Nginx: `docker compose up -d nginx`

## 📝 Notes

- All container communication happens on the internal Docker bridge network (`172.19.0.0/16`)
- Only Tailscale and Nginx are exposed externally
- Ollama models are stored in the `ollama` volume
- Open WebUI data is persisted in the `open-webui` volume
- No data leaves your device without going through Tailscale's encrypted tunnel

## 📚 Resources

- [Tailscale Docs](https://tailscale.com/kb)
- [Open WebUI GitHub](https://github.com/open-webui/open-webui)
- [Ollama Documentation](https://ollama.ai)
- [Nginx Docs](https://nginx.org/en/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)

## 📄 License

MIT License - Feel free to use, modify, and share
## 📝 Version History

- **v2025.12.6.001** - Initial release with Tailscale-managed valid HTTPS certificates (zero warnings)
Found a bug or have an improvement? Submit a pull request or open an issue on GitHub.

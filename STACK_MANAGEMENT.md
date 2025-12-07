# Stack Management Guide

This document explains how to manage both production and beta stacks together or independently.

## 📊 Three Ways to Manage Stacks

### Method 1: Ansible (Infrastructure as Code) 🆕

Use Ansible for idempotent, declarative stack management:

```bash
cd ansible

# One-time setup
make install

# Manage stacks
make start                    # Start both stacks
make start-prod               # Start only production
make restart-beta             # Restart only beta
make status                   # View status
make stop                     # Stop both stacks
```

**Pros:**
- ✅ Idempotent operations (safe to run multiple times)
- ✅ Infrastructure as code (version controlled)
- ✅ Detailed logging and error handling
- ✅ Easily extensible for multi-server setups
- ✅ CI/CD integration friendly

**Cons:**
- ❌ Requires Ansible installation
- ❌ Slightly more verbose for simple tasks

See [ansible/README.md](ansible/README.md) for complete documentation.

### Method 2: Helper Script (Most Convenient)

Use the `manage.sh` helper script for easy commands:

```bash
# Start both stacks
./manage.sh start

# Start only production
./manage.sh start-prod

# Start only beta
./manage.sh start-beta

# Restart both
./manage.sh restart

# Restart only beta
./manage.sh restart-beta

# View status
./manage.sh status

# View logs (all)
./manage.sh logs

# View logs (production only)
./manage.sh logs-prod

# View logs (beta only)
./manage.sh logs-beta

# Show all commands
./manage.sh help
```

**Pros:**
- ✅ Simple, memorable commands
- ✅ Easy to remember (no service names needed)
- ✅ Built-in help

**Cons:**
- ❌ One more abstraction layer

### Method 3: Direct Docker Compose

Use Docker Compose directly from the root directory:

```bash
# Start both stacks
docker compose --profile all up -d

# Start only production
docker compose --profile prod up -d

# Restart specific services
docker compose restart open-webui2 tailscale-sidecar nginx-prod

# View all containers
docker compose ps

# Stop both stacks
docker compose down
```

**Pros:**
- ✅ Direct control with Docker Compose
- ✅ No additional scripts needed
- ✅ Standard Docker workflow

**Cons:**
- ❌ Need to remember profile flags
- ❌ More verbose commands

### Method 4: Individual Directory Compose Files

Manage each stack separately from its directory:

```bash
# Start production
cd production
docker compose up -d

# Start beta
cd beta
docker compose up -d

# Restart only production
cd production && docker compose restart

# Restart only beta
cd beta && docker compose restart

# Stop both (must run from each directory)
cd production && docker compose down
cd beta && docker compose down
```

**Pros:**
- ✅ Maximum isolation between stacks
- ✅ Simple single-service workflow

**Cons:**
- ❌ More typing and directory changes
- ❌ Must run commands in each directory

## 🎯 Recommended Workflow

### Choose Your Tool

| Scenario | Recommended Method |
|----------|-------------------|
| **Daily development** | Bash script (`./manage.sh`) |
| **CI/CD pipelines** | Ansible (`cd ansible && make start`) |
| **Multi-server deployments** | Ansible |
| **Quick debugging** | Docker Compose directly |
| **Infrastructure as code** | Ansible |
| **Simplest learning curve** | Bash script |

### For Daily Development (Bash Script)

```bash
# Morning: Start everything
./manage.sh start

# During work: Restart beta when testing
./manage.sh restart-beta

# Evening: Stop everything
./manage.sh stop
```

### For Production Deployments (Ansible)

```bash
cd ansible

# One-time setup
make install
make validate

# Deploy
make start-prod

# Monitor
make status

# Update and restart
make restart-prod
```

### For Emergency Restarts (Docker Compose)

# Evening: Stop everything
./manage.sh stop
```

### For Emergency Restarts

Use root docker-compose:

```bash
# Restart just the reverse proxy (if experiencing connection issues)
docker compose restart nginx-prod nginx-beta

# Restart just Tailscale (if VPN connection drops)
docker compose restart tailscale-sidecar tailscale-sidecar-beta
```

### For Detailed Troubleshooting

Use individual directories:

```bash
# Isolate and debug production
cd production
docker compose logs -f
docker compose exec open-webui2 /bin/sh
```

## 📋 Service Names Reference

### Production Services
- `open-webui2` - Open WebUI application
- `tailscale-sidecar` - Tailscale VPN connection
- `nginx-prod` - Reverse proxy

### Beta Services
- `open-webui-beta` - Open WebUI (beta)
- `tailscale-sidecar-beta` - Tailscale VPN (beta)
- `nginx-beta` - Reverse proxy (beta)

## 🔍 Monitoring

### Quick Health Check

```bash
# Check all services running
./manage.sh status

# Or manually
docker compose ps
```

### Detailed Logs

```bash
# All services in real-time
./manage.sh logs

# Production only
./manage.sh logs-prod

# Beta only
./manage.sh logs-beta

# Specific service
docker compose logs -f open-webui2
```

### Tailscale Status

```bash
# Production Tailscale
docker compose exec tailscale-sidecar tailscale status

# Beta Tailscale
docker compose exec tailscale-sidecar-beta tailscale status
```

## 🚨 Troubleshooting

### "Port already in use"

Ports 8080 and 8081 must be available:

```bash
# Check what's using them
lsof -i :8080
lsof -i :8081

# Stop conflicting service and restart
./manage.sh restart
```

### "Tailscale won't connect"

```bash
# Check Tailscale logs
docker compose logs tailscale-sidecar

# Restart Tailscale
docker compose restart tailscale-sidecar tailscale-sidecar-beta
```

### "502 Bad Gateway"

```bash
# Restart reverse proxy
docker compose restart nginx-prod nginx-beta

# Or just the problematic one
docker compose restart nginx-beta
```

### "Need to approve new Tailscale device"

Go to https://login.tailscale.com/admin/machines and approve `jarvis` or `jarvis-beta`

## 📚 Related Documentation

- [`README.md`](README.md) - Project overview
- [`DEVELOPMENT.md`](DEVELOPMENT.md) - Development guide
- [`BETA_QUICKSTART.md`](BETA_QUICKSTART.md) - Beta quick reference
- [`production/README.md`](production/README.md) - Production details
- [`beta/README.md`](beta/README.md) - Beta details

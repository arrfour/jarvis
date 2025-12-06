# Stack Management Guide

This document explains how to manage both production and beta stacks together or independently.

## 📊 Two Ways to Manage Stacks

### Method 1: Unified Root Docker Compose (Recommended)

Manage both stacks from the project root directory with a single `docker-compose.yaml`:

```bash
# Start both stacks
docker compose up -d

# View all containers
docker compose ps

# Restart both stacks
docker compose restart

# Stop both stacks
docker compose down

# Restart only production
docker compose restart open-webui2 tailscale-sidecar nginx-prod

# Restart only beta
docker compose restart open-webui-beta tailscale-sidecar-beta nginx-beta

# View logs (all stacks)
docker compose logs -f

# View logs (production only)
docker compose logs -f open-webui2 tailscale-sidecar nginx-prod
```

**Pros:**
- ✅ Single command to start everything
- ✅ Can still control stacks independently
- ✅ Easy to see all containers: `docker compose ps`
- ✅ Familiar docker compose workflow

**Cons:**
- ❌ Need to specify service names when restarting individual services

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

### Method 3: Individual Directory Compose Files (Original)

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
- ✅ Most isolation between stacks
- ✅ Familiar single-service workflow

**Cons:**
- ❌ More typing
- ❌ Must `cd` to each directory

## 🎯 Recommended Workflow

### For Daily Development

Use the helper script:

```bash
# Morning: Start everything
./manage.sh start

# During work: Restart beta when testing
./manage.sh restart-beta

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

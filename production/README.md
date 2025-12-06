# Production Environment

This directory contains the production Open WebUI stack running on your Tailnet.

## Quick Start

```bash
cd production
cp .env.example .env
# Edit .env with your Tailscale auth key
docker compose up -d
```

## Access

- **URL:** `https://jarvis.tailcd013.ts.net`
- **Status:** Check with `docker compose ps`

## Volumes

- `ollama` - Ollama models and cache
- `open-webui` - Open WebUI data and settings
- `tailscale-sidecar-state` - Tailscale VPN state

## Cleanup

```bash
# Stop services
docker compose down

# Remove all data (careful!)
docker compose down -v
```

For full documentation, see `../README.md`

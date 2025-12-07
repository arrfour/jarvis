# Beta Environment

This directory contains the beta development stack for testing new features.

## Quick Start

```bash
cd beta
cp .env.example .env
# Edit .env with your Tailscale beta auth key (reusable)
docker compose up -d
```

## Access

- **URL:** `https://jarvis-beta.YOUR_TAILNET.ts.net` (replace `YOUR_TAILNET` with your actual Tailnet name)
- **Visual Indicator:** Red beta branding (favicon + logo)
- **Status:** Check with `docker compose ps`

## Development

This stack runs in parallel with production. Use it to:
- Test new features without affecting production
- Persistent beta admin account across restarts
- Optional data reset between major features

## Reset Beta Data

To start fresh (removes all test data):

```bash
docker volume rm jarvis_ollama-beta jarvis_open-webui-beta
docker compose restart open-webui-beta
```

## Volumes

- `ollama-beta` - Ollama models and cache (beta)
- `open-webui-beta` - Open WebUI data (beta)
- `tailscale-sidecar-beta-state` - Tailscale VPN state (beta)

For full development documentation, see `../DEVELOPMENT.md`

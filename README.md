# Jarvis - Open WebUI on Tailscale

A containerized Open WebUI instance with Ollama support, accessible securely via Tailscale with SSL/TLS encryption.

## Features

- 🤖 **Open WebUI** - Web interface for LLM interactions
- 🔐 **Tailscale Network** - Secure, encrypted, private network access
- 🔒 **SSL/TLS** - Self-signed certificates for HTTPS
- 🔄 **Reverse Proxy** - Nginx for routing and future service expansion
- 📦 **Containerized** - Docker Compose for easy deployment

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Tailscale account (free at https://tailscale.com)
- Tailscale auth key with "Reusable" and "Ephemeral" checked

### Setup

1. **Generate Tailscale Auth Key**
   - Go to https://login.tailscale.com/admin/settings/keys
   - Create new Auth Key
   - Check: "Reusable" and "Ephemeral"
   - Copy the key

2. **Create `.env` file**
   ```bash
   echo "TS_AUTHKEY=tskey-api-YOUR_KEY_HERE" > .env
   ```

3. **Start the stack**
   ```bash
   docker compose up -d
   ```

4. **Approve device in Tailscale Admin**
   - Go to https://login.tailscale.com/admin/machines
   - Find and approve the `jarvis` device

5. **Access Open WebUI**
   ```
   https://jarvis.tailcd013.ts.net
   ```
   (Replace `tailcd013` with your actual Tailnet domain)

## Architecture

```
Tailscale Serve (HTTPS on default port)
       ↓
Nginx (port 8080 HTTP)
       ↓
Open WebUI (port 8080 internal)
       ↓
Ollama (internal Docker network)
```

## Files

- **`compose.yaml`** - Docker Compose configuration
- **`nginx.conf`** - Nginx reverse proxy configuration
- **`.env`** - Environment variables (not tracked in git, see `.env.example`)
- **`certs/`** - SSL certificates (auto-generated, not tracked in git)

## Configuration

### Access Points

- **FQDN**: `https://jarvis.tailcd013.ts.net` (via Tailscale Serve)
- **Direct IP**: `https://100.x.x.x:8443` (if needed)
- **Local**: `https://127.0.0.1:8443` (from the host machine)

### Adding More Services

1. Add service to `compose.yaml` on the `internal` network
2. Add location block in `nginx.conf`:
   ```nginx
   location /api/ {
       proxy_pass http://service-name:port/;
       proxy_set_header Host $host;
       # ... other headers
   }
   ```
3. Restart Nginx:
   ```bash
   docker compose up -d nginx
   ```

## Network Details

- **Internal Network**: `172.19.0.0/16` (bridge network for containers)
- **Tailscale IP**: Dynamic (assigned per device approval)
- **SSL Certs**: Self-signed, valid for 365 days

## Troubleshooting

### Device won't approve in Tailscale
- Check auth key is valid and reusable
- Wait a few moments and refresh Tailscale Admin

### ERR_TOO_MANY_REDIRECTS
- Clear browser cookies for the domain
- Restart Nginx: `docker compose restart nginx`

### 502 Bad Gateway
- Check Open WebUI is running: `docker compose ps`
- Check Nginx logs: `docker compose logs nginx`
- Verify internal network connectivity: `docker compose exec nginx ping open-webui2`

## Maintenance

### Regenerate SSL Certificates
```bash
rm -rf certs/
mkdir -p certs
openssl req -x509 -newkey rsa:4096 -nodes -out certs/server.crt -keyout certs/server.key -days 365 \
  -subj "/CN=jarvis"
docker compose restart nginx
```

### View Logs
```bash
docker compose logs -f nginx
docker compose logs -f open-webui2
docker compose logs -f tailscale-sidecar
```

### Update Images
```bash
docker compose pull
docker compose up -d
```

## License

This project is provided as-is for personal use.

## See Also

- [Tailscale Documentation](https://tailscale.com/kb)
- [Open WebUI GitHub](https://github.com/open-webui/open-webui)
- [Ollama Documentation](https://ollama.ai)

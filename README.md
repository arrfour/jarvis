# Jarvis - Open WebUI on Tailscale

A containerized Open WebUI instance with Ollama support, accessible securely via Tailscale with SSL/TLS encryption.

## ✨ Features

- 🤖 **Open WebUI** - Web interface for LLM interactions with Ollama backend
- 🔐 **Tailscale Network** - Secure, encrypted private network access (no port forwarding needed)
- 🔒 **SSL/TLS** - Self-signed certificates for HTTPS (valid 365 days)
- 🔄 **Reverse Proxy** - Nginx for routing and future service expansion
- 📦 **Containerized** - Docker Compose for reproducible deployment

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Tailscale account (free at https://tailscale.com)
- Tailscale auth key with "Reusable" and "Ephemeral" flags

### Setup (5 minutes)

1. **Clone this repository**
   ```bash
   git clone https://github.com/arrfour/jarvis.git
   cd jarvis
   ```

2. **Generate Tailscale Auth Key**
   - Go to https://login.tailscale.com/admin/settings/keys
   - Create new Auth Key
   - ✓ Check "Reusable"
   - ✓ Check "Ephemeral"
   - Copy the key

3. **Create `.env` file**
   ```bash
   cp .env.example .env
   # Edit .env and paste your Tailscale auth key
   nano .env
   ```

4. **Start the stack**
   ```bash
   docker compose up -d
   ```

5. **Approve device in Tailscale**
   - Go to https://login.tailscale.com/admin/machines
   - Find and approve the `jarvis` device

6. **Access Open WebUI**
   ```
   https://jarvis.tailcd013.ts.net
   ```
   (Replace `tailcd013` with your Tailnet domain)

## 📐 Architecture

```
Your Device on Tailnet
       ↓
Tailscale Serve (HTTPS default port 443)
       ↓
Tailscale Sidecar Container (host network)
       ↓
Nginx Reverse Proxy (127.0.0.1:8080)
       ↓
Open WebUI Container (internal Docker network)
       ↓
Ollama (local LLM backend)
```

## 📁 Project Structure

```
jarvis/
├── .env.example          # Template for environment variables (copy to .env)
├── .gitignore           # Excludes secrets, certs, volumes
├── README.md            # This file
├── compose.yaml         # Docker Compose configuration
├── nginx.conf           # Nginx reverse proxy config
├── certs/               # SSL certificates (auto-generated, not in git)
└── .git/                # Version control
```

## 🔌 Access Points

| URL | Purpose | Notes |
|-----|---------|-------|
| `https://jarvis.tailcd013.ts.net` | Primary access via Tailscale | No port needed, secure FQDN |
| `https://100.x.x.x:8443` | Direct IP access | Use if FQDN fails |
| `https://127.0.0.1:8443` | Local access (host machine) | For debugging |

Replace `tailcd013` with your actual Tailnet domain and `100.x.x.x` with your device's Tailscale IP.

## 🛠️ Configuration

### Environment Variables (`.env`)

```bash
TS_AUTHKEY=tskey-api-YOUR_KEY_HERE
```

Generate at: https://login.tailscale.com/admin/settings/keys

### SSL Certificates

Self-signed certificates are automatically generated on first run and stored in `certs/`:
- Valid for 365 days
- Not tracked in git (for security)
- Regenerate if needed (see Maintenance section)

## 📦 Services

### Open WebUI Container
- **Image**: `ghcr.io/open-webui/open-webui:Latest`
- **Port**: 8080 (internal, not exposed)
- **GPU**: Enabled (remove `gpus: all` if not needed)
- **Volumes**: 
  - `ollama` - LLM model cache
  - `open-webui` - Application data

### Nginx Reverse Proxy
- **Image**: `nginx:alpine`
- **Ports**: 127.0.0.1:8080 (HTTP), 127.0.0.1:8443 (HTTPS)
- **Config**: `./nginx.conf`
- **SSL**: Self-signed certs from `./certs/`

### Tailscale Sidecar
- **Image**: `tailscale/tailscale:latest`
- **Hostname**: `jarvis`
- **Network**: Host network (for Serve functionality)
- **Auth**: Uses `TS_AUTHKEY` from `.env`

## 🔧 Maintenance

### View Logs
```bash
docker compose logs -f nginx
docker compose logs -f open-webui2
docker compose logs -f tailscale-sidecar
```

### Restart Services
```bash
docker compose restart nginx          # Restart Nginx
docker compose restart open-webui2    # Restart Open WebUI
docker compose restart               # Restart all
```

### Regenerate SSL Certificates
```bash
rm -rf certs/
mkdir -p certs
openssl req -x509 -newkey rsa:4096 -nodes \
  -out certs/server.crt -keyout certs/server.key \
  -days 365 -subj "/CN=jarvis"
docker compose restart nginx
```

### Update Images
```bash
docker compose pull
docker compose up -d
```

### Stop Everything
```bash
docker compose down
```

Remove volumes too (WARNING: deletes data):
```bash
docker compose down -v
```

## 🆘 Troubleshooting

### Device won't approve in Tailscale Admin
- Verify auth key is valid and reusable
- Check Tailscale logs: `docker compose logs tailscale-sidecar`
- Wait a few seconds and refresh the admin panel

### Can't connect to `jarvis.tailcd013.ts.net`
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
- Verify internal network: `docker compose exec nginx ping open-webui2`

### SSL Certificate Warnings
- Normal for self-signed certs on first access
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

## 🤝 Contributing

Found a bug or have an improvement? Submit a pull request or open an issue on GitHub.

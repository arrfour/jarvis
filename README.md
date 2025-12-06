# Jarvis - Open WebUI on Tailscale

A containerized Open WebUI instance with Ollama support, accessible securely via Tailscale with **automatically-issued valid HTTPS certificates** (no self-signed certificate warnings).

## ✨ Features

- 🤖 **Open WebUI** - Web interface for LLM interactions with Ollama backend
- 🔐 **Tailscale Network** - Secure, encrypted private network access (no port forwarding needed)
- ✅ **Valid HTTPS Certificates** - Automatic Tailscale certificates on your Tailnet (zero warnings)
- 🔄 **Reverse Proxy** - Nginx for routing and future service expansion
- 📦 **Containerized** - Docker Compose for reproducible deployment
- 🎯 **Tailnet-Only** - Designed for secure access only via Tailscale

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
Tailscale Serve (provides HTTPS with valid certificates)
       ↓
Tailscale Sidecar Container (host network)
       ↓
Nginx Reverse Proxy (127.0.0.1:8080 HTTP)
       ↓
Open WebUI Container (internal Docker network)
       ↓
Ollama (local LLM backend)
```

**Key Points:**
- ✅ **No certificate warnings** - Tailscale issues valid certs automatically
- 🔒 **Encrypted end-to-end** - HTTPS from browser to Tailscale Serve
- 🚀 **Simple setup** - Tailscale handles all HTTPS complexity
- 🎯 **Tailnet-only** - No exposure to the public internetama (local LLM backend)
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

| URL | Purpose | Certificate |
|-----|---------|-------------|
| `https://jarvis.tailcd013.ts.net` | Primary access via Tailscale | ✅ Valid (auto-issued) |
| `https://100.x.x.x:8443` | Direct IP (not recommended) | ⚠️ Self-signed |
| `https://127.0.0.1:8443` | Local access (host machine) | ⚠️ Self-signed |

**Recommended:** Always use the Tailnet FQDN (`jarvis.tailcd013.ts.net`) for valid certificates and zero warnings.

Replace `tailcd013` with your actual Tailnet domain.

## 🛠️ Configuration

### Environment Variables (`.env`)

```bash
TS_AUTHKEY=tskey-api-YOUR_KEY_HERE
```

Generate at: https://login.tailscale.com/admin/settings/keys

### Certificates

**No manual certificate management needed!**

Tailscale automatically issues and renews valid HTTPS certificates for your device on your Tailnet. Certificates are managed entirely by Tailscale and require zero configuration.

## 📦 Services

### Open WebUI Container
- **Image**: `ghcr.io/open-webui/open-webui:Latest`
- **Port**: 8080 (internal, not exposed)
- **GPU**: Enabled (remove `gpus: all` if not needed)
- **Volumes**: 
  - `ollama` - LLM model cache
  - `open-webui` - Application data

### Nginx Reverse Proxy
### Nginx Reverse Proxy
- **Image**: `nginx:alpine`
- **Ports**: 127.0.0.1:8080 (HTTP only)
- **Config**: `./nginx.conf`
- **SSL**: Handled by Tailscale Serve (no local certificates)
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

**Not needed anymore!** Tailscale handles all certificate issuance and renewal automatically. Your Tailnet domain certificates are managed by Tailscale and updated without any manual intervention.

If you absolutely need to reset Tailscale:
```bash
docker compose exec tailscale-sidecar tailscale logout
docker compose restart tailscale-sidecar
# Then approve device again in Tailscale Admin
docker compose exec tailscale-sidecar tailscale serve --bg http://127.0.0.1:8080
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
### SSL Certificate Warnings

**There should be none!** Tailscale provides valid HTTPS certificates automatically on your Tailnet domain. Access `https://jarvis.tailcd013.ts.net` and your browser should trust the certificate immediately.
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

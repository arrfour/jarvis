#!/bin/sh
# tailscale-entrypoint.sh
#
# Custom entrypoint for the tailscale container.
#
# Responsibilities:
#   1. Start the Tailscale daemon (containerboot)
#   2. Wait for tailscaled to authenticate on the tailnet
#   3. Poll the app's health endpoint until it's ready
#   4. Register this host as a svc:jarvis VIP backend via `tailscale serve`
#   5. Expose the Ollama API on port 11434 of this tailnet node
#   6. Trap SIGTERM to withdraw both serves cleanly on `docker compose down`

set -e

APP_HEALTH_URL="${APP_HEALTH_URL:-http://nginx:80/health}"
VIP_SERVICE="${VIP_SERVICE:-svc:jarvis}"
VIP_BACKEND="${VIP_BACKEND:-http://nginx:80}"
VIP_MODE="${VIP_MODE:-http}"
OLLAMA_SERVE_URL="${OLLAMA_SERVE_URL:-http://ollama:11434}"
TS_READY_TIMEOUT="${TS_READY_TIMEOUT:-60}"

# Detect socket path (tailscale/tailscale image may use /tmp if /var/run is restricted)
TS_SOCKET="/var/run/tailscale/tailscaled.sock"
if [ ! -S "$TS_SOCKET" ] && [ -S "/tmp/tailscaled.sock" ]; then
    TS_SOCKET="/tmp/tailscaled.sock"
fi

tailscale_cli() {
    tailscale --socket="$TS_SOCKET" "$@"
}

# ── 1. Start Tailscale daemon ─────────────────────────────────────────────────
echo "[ts-entrypoint] Starting Tailscale daemon..."
/usr/local/bin/containerboot &
BOOT_PID=$!

# ── 2. Wait for tailscaled to be ready ───────────────────────────────────────
echo "[ts-entrypoint] Waiting for tailscaled (up to ${TS_READY_TIMEOUT}s)..."
i=0
while [ "$i" -lt "$TS_READY_TIMEOUT" ]; do
  if [ ! -S "$TS_SOCKET" ] && [ -S "/tmp/tailscaled.sock" ]; then TS_SOCKET="/tmp/tailscaled.sock"; fi
  tailscale_cli status >/dev/null 2>&1 && break
  sleep 1
  i=$((i + 1))
done

if ! tailscale_cli status >/dev/null 2>&1; then
  echo "[ts-entrypoint] ERROR: Tailscale not ready after ${TS_READY_TIMEOUT}s — aborting."
  wait "$BOOT_PID"
  exit 1
fi

echo "[ts-entrypoint] Tailscale daemon ready (socket: ${TS_SOCKET})."

# ── 3. Poll app health before registering ────────────────────────────────────
echo "[ts-entrypoint] Waiting for app health at ${APP_HEALTH_URL} ..."
until wget -qO- "$APP_HEALTH_URL" >/dev/null 2>&1; do
  sleep 5
done
echo "[ts-entrypoint] App healthy."

# ── 4. Register VIP backend for Open WebUI ───────────────────────────────────
echo "[ts-entrypoint] Registering ${VIP_SERVICE} (${VIP_MODE}) → ${VIP_BACKEND} ..."

if [ "$VIP_MODE" = "http" ]; then
    if tailscale_cli serve --bg --service="$VIP_SERVICE" --http=80 "$VIP_BACKEND"; then
        echo "[ts-entrypoint] Port 80 (HTTP) registered successfully."
    else
        echo "[ts-entrypoint] Failed to register Port 80 (HTTP)."
        exit 1
    fi

    if tailscale_cli serve --bg --service="$VIP_SERVICE" --tcp=443 "tcp://${VIP_BACKEND#*://}"; then
        echo "[ts-entrypoint] VIP (dual-port HTTP/TCP) registered successfully."
    else
        echo "[ts-entrypoint] Failed to register Port 443 (TCP)."
        exit 1
    fi
else
    if tailscale_cli serve --bg --service="$VIP_SERVICE" "$VIP_BACKEND"; then
        echo "[ts-entrypoint] VIP (HTTPS) registered successfully."
    else
        echo "[ts-entrypoint] Failed to register VIP (HTTPS)."
        exit 1
    fi
fi

# ── 5. Expose Ollama API on port 11434 of this tailnet node ──────────────────
echo "[ts-entrypoint] Registering Ollama API serve on port 11434 → ${OLLAMA_SERVE_URL} ..."
if tailscale_cli serve --bg --http=11434 "$OLLAMA_SERVE_URL"; then
    echo "[ts-entrypoint] Ollama API accessible at http://jarvis:11434 on Tailnet."
else
    echo "[ts-entrypoint] WARNING: Failed to register Ollama API serve — continuing anyway."
fi

echo "[ts-entrypoint] All registrations complete. Monitoring for shutdown..."

# ── 6. Clean withdrawal on SIGTERM / SIGINT ──────────────────────────────────
trap 'echo "[ts-entrypoint] Withdrawing serves..."; \
      tailscale_cli serve --service="$VIP_SERVICE" --remove "$VIP_BACKEND" 2>/dev/null || true; \
      [ "$VIP_MODE" = "http" ] && tailscale_cli serve --service="$VIP_SERVICE" --remove "tcp://${VIP_BACKEND#*://}" 2>/dev/null || true; \
      tailscale_cli serve --http=11434 off 2>/dev/null || true; \
      kill "$BOOT_PID" 2>/dev/null; \
      wait "$BOOT_PID" 2>/dev/null; \
      exit 0' TERM INT

# Keep container alive while daemon runs
wait "$BOOT_PID"

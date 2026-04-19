#!/bin/sh
# tailscale-entrypoint.sh
#
# Custom entrypoint for the tailscale-sidecar container.
#
# Responsibilities:
#   1. Start the Tailscale daemon (containerboot)
#   2. Wait for tailscaled to authenticate on the tailnet
#   3. Poll the app's health endpoint until it's ready
#   4. Register this host as a svc:jarvis VIP backend via `tailscale serve`
#   5. Trap SIGTERM to withdraw the VIP cleanly on `docker compose down`
#
# Why here instead of a separate sidecar: tailscale-sidecar already owns the
# tailscale binary and daemon, and uses network_mode: host — so it can reach
# localhost:8080 (nginx) without any host-native Tailscale requirement.

set -e

APP_HEALTH_URL="${APP_HEALTH_URL:-http://127.0.0.1:8080/health}"
VIP_SERVICE="${VIP_SERVICE:-svc:jarvis}"
VIP_BACKEND="${VIP_BACKEND:-https://localhost:443}"
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
  # Fallback check for socket appearance
  if [ ! -S "$TS_SOCKET" ] && [ -S "/tmp/tailscaled.sock" ]; then TS_SOCKET="/tmp/tailscaled.sock"; fi
  
  tailscale_cli status >/dev/null 2>&1 && break
  sleep 1
  i=$((i + 1))
done

if ! tailscale_cli status >/dev/null 2>&1; then
  echo "[ts-entrypoint] ERROR: Tailscale not ready after ${TS_READY_TIMEOUT}s — skipping VIP registration."
  wait "$BOOT_PID"
  exit 1
fi

echo "[ts-entrypoint] Tailscale daemon ready (socket: ${TS_SOCKET})."

# ── 3. Poll app health before registering VIP ────────────────────────────────
# tailscale-sidecar is network_mode: host, so localhost:8080 = nginx on the host.
echo "[ts-entrypoint] Waiting for app health at ${APP_HEALTH_URL} ..."
until wget -qO- "$APP_HEALTH_URL" >/dev/null 2>&1; do
  sleep 5
done

echo "[ts-entrypoint] App healthy."

# ── 4. Register VIP backend ──────────────────────────────────────────────────
# Mode detection (https default)
VIP_MODE="${VIP_MODE:-https}"

echo "[ts-entrypoint] Registering ${VIP_SERVICE} (${VIP_MODE}) → ${VIP_BACKEND} ..."

if [ "$VIP_MODE" = "http" ]; then
    # Dual-port registration (to satisfy Tailscale port 443 requirement while bypassing ACME rate limit)
    echo "[ts-entrypoint] Registering Port 80 (HTTP) ..."
    tailscale_cli serve --bg --service="$VIP_SERVICE" --http=80 "$VIP_BACKEND" || true
    
    echo "[ts-entrypoint] Registering Port 443 (TCP Pass-through) ..."
    if tailscale_cli serve --bg --service="$VIP_SERVICE" --tcp=443 "tcp://${VIP_BACKEND#*://}"; then
        echo "[ts-entrypoint] VIP (Dual-Port HTTP/TCP) registered successfully. Monitoring for shutdown..."
    else
        echo "[ts-entrypoint] Failed to register VIP (Dual-Port)."
        exit 1
    fi
else
    # Register as HTTPS on port 443 (default)
    if tailscale_cli serve --bg --service="$VIP_SERVICE" "$VIP_BACKEND"; then
        echo "[ts-entrypoint] VIP (HTTPS) registered successfully. Monitoring for shutdown..."
    else
        echo "[ts-entrypoint] Failed to register VIP (HTTPS)."
        exit 1
    fi
fi

# ── 5. Clean withdrawal on SIGTERM / SIGINT ──────────────────────────────────
trap 'echo "[ts-entrypoint] Withdrawing ${VIP_SERVICE} backend..."; \
      tailscale_cli serve --service="$VIP_SERVICE" --remove "$VIP_BACKEND" 2>/dev/null || true; \
      kill "$BOOT_PID" 2>/dev/null; \
      wait "$BOOT_PID" 2>/dev/null; \
      exit 0' TERM INT

# Keep container alive while daemon runs
wait "$BOOT_PID"

#!/bin/bash
# Wait for Tailscale daemon to start and configure Serve

set -e

# Start the Tailscale daemon in the background
/usr/local/bin/containerboot &
BOOT_PID=$!

# Wait for Tailscale to be ready (max 60 seconds)
echo "Waiting for Tailscale to be ready..."
for i in {1..60}; do
  if tailscale status >/dev/null 2>&1; then
    echo "Tailscale is ready"
    break
  fi
  sleep 1
done

# Check if device is authenticated
echo "Checking Tailscale status..."
tailscale status

# Configure Tailscale Serve to proxy to localhost:8080
echo "Configuring Tailscale Serve..."
tailscale serve https / http://127.0.0.1:8080 || echo "Note: Serve configuration may require device approval first"

# Keep the daemon running
wait $BOOT_PID

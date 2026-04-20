#!/bin/bash
# Jarvis Stack Manager
#
# Usage: ./manage.sh [command] [--cpu]

set -e

trap 'echo "❌ Error on line $LINENO"; exit 1' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-detect container runtime (Podman vs Docker)
function detect_container_runtime() {
    if [ -n "$DOCKER_HOST" ]; then
        return
    fi

    local podman_socket="/run/user/$(id -u)/podman/podman.sock"
    if [ -S "$podman_socket" ]; then
        export DOCKER_HOST="unix://$podman_socket"
        echo "🐋 Using Podman (rootless socket)"
        return
    fi

    if [ -S "/run/podman/podman.sock" ]; then
        export DOCKER_HOST="unix:///run/podman/podman.sock"
        echo "🐋 Using Podman (root socket)"
        return
    fi

    if [ -S "/var/run/docker.sock" ]; then
        echo "🐋 Using Docker"
        return
    fi

    echo "❌ No container runtime socket found!"
    echo "   Please ensure Docker or Podman is running."
    echo ""
    echo "   For Podman (rootless): systemctl --user enable --now podman.socket"
    echo "   For Docker:            sudo systemctl start docker"
    exit 1
}

detect_container_runtime

# Load environment variables safely (guards against space/metacharacter injection)
set -a
[ -f "$SCRIPT_DIR/.env" ] && source "$SCRIPT_DIR/.env"
set +a

COMPOSE_FILES="-f docker-compose.yaml"

function detect_hardware() {
    for arg in "$@"; do
        if [ "$arg" == "--cpu" ]; then
            echo "ℹ️  CPU mode forced."
            return
        fi
    done

    if command -v nvidia-smi &> /dev/null || [ -e /dev/nvidia0 ]; then
        echo "✅ NVIDIA GPU detected. Using NVIDIA configuration."
        COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.nvidia.yaml"
        return
    fi

    if [ -e /dev/kfd ]; then
        echo "✅ AMD GPU detected. Using AMD configuration."
        COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.amd.yaml"
        return
    fi

    echo "⚠️  No GPU detected. Falling back to CPU mode."
}

function run_compose() {
    if docker compose version &>/dev/null 2>&1; then
        docker compose $COMPOSE_FILES "$@"
    elif command -v docker-compose &>/dev/null; then
        docker-compose $COMPOSE_FILES "$@"
    else
        echo "❌ Docker Compose is not installed"
        exit 1
    fi
}

function wait_for_tailscale() {
    local container=$1
    echo "⏳ Waiting for Tailscale to be ready in $container..."
    for i in {1..30}; do
        if docker exec "$container" tailscale status >/dev/null 2>&1; then
            echo "✅ $container is ready!"
            return 0
        fi
        sleep 1
    done
    echo "⚠️  Timed out waiting for Tailscale in $container"
    return 1
}

function nuke_stack() {
    echo "💥 WARNING: This will PERMANENTLY DELETE all volumes and data!"
    echo "   Includes: Ollama models, Open WebUI data, conversation history."
    read -p "Type 'yes' to confirm: " confirm
    if [ "$confirm" = "yes" ]; then
        echo "💣 Nuking stack and volumes..."
        run_compose down -v
        echo "✅ Stack and volumes destroyed."
    else
        echo "❌ Cancelled."
    fi
}

detect_hardware "$@"

case "$1" in
  "")
    if [ -f "$SCRIPT_DIR/tui.sh" ] && command -v dialog &> /dev/null; then
      exec "$SCRIPT_DIR/tui.sh"
    else
      echo "💡 Tip: Install 'dialog' for interactive TUI: sudo apt install dialog"
      echo ""
      exec "$SCRIPT_DIR/manage.sh" help
    fi
    ;;

  start|up)
    echo "🚀 Starting Jarvis stack..."
    run_compose up -d
    echo "✅ Stack running!"
    echo ""
    run_compose ps
    echo ""
    wait_for_tailscale "tailscale" || true
    ;;

  stop|down)
    echo "🛑 Stopping Jarvis stack..."
    run_compose down
    echo "✅ Stack stopped."
    ;;

  restart)
    echo "🔄 Restarting Jarvis stack..."
    run_compose restart
    echo "✅ Stack restarted."
    echo ""
    wait_for_tailscale "tailscale" || true
    ;;

  nuke|destroy)
    nuke_stack
    ;;

  status|ps)
    echo "📊 Stack Status:"
    run_compose ps
    ;;

  logs)
    echo "📋 Logs (all services) — Ctrl+C to exit"
    run_compose logs -f
    ;;

  logs-ollama)
    echo "📋 Ollama logs — Ctrl+C to exit"
    run_compose logs -f ollama
    ;;

  logs-webui)
    echo "📋 Open WebUI logs — Ctrl+C to exit"
    run_compose logs -f open-webui
    ;;

  logs-tailscale)
    echo "📋 Tailscale logs — Ctrl+C to exit"
    run_compose logs -f tailscale
    ;;

  config)
    echo "📝 Docker Compose Configuration:"
    run_compose config
    ;;

  validate)
    echo "✓ Validating docker-compose.yaml..."
    run_compose config > /dev/null
    echo "✅ Configuration is valid!"
    ;;

  serve-config)
    echo "🔧 Tailscale serve status:"
    docker exec tailscale tailscale serve status 2>/dev/null || echo "⚠️  Tailscale container not running"
    echo ""
    echo "Access URLs (tailnet only):"
    echo "  Web UI: https://jarvis.YOUR_TAILNET.ts.net"
    echo "  Ollama: http://jarvis.YOUR_TAILNET.ts.net:11434"
    ;;

  versions)
    echo "📊 Image Versions:"
    echo ""
    CONFIGURED=$(awk '/^  open-webui:/{flag=1} flag && /image:/{gsub(/.*image:[[:space:]]+/, ""); gsub(/[[:space:]]+#.*/, ""); print; exit}' "$SCRIPT_DIR/docker-compose.yaml")
    RUNNING=$(docker inspect open-webui --format='{{.Config.Image}}' 2>/dev/null || echo "Not running")
    OLLAMA_RUNNING=$(docker inspect ollama --format='{{.Config.Image}}' 2>/dev/null || echo "Not running")
    echo "  Open WebUI:"
    echo "    Configured: $CONFIGURED"
    echo "    Running:    $RUNNING"
    echo ""
    echo "  Ollama:"
    echo "    Running:    $OLLAMA_RUNNING"
    ;;

  monitor-gpu)
    echo "📊 GPU Monitor"

    if command -v nvidia-smi &> /dev/null; then
        echo "✅ NVIDIA host detected. Running nvidia-smi..."
        nvidia-smi -l 1
        exit 0
    fi

    if ! docker ps | grep -q "ollama"; then
        echo "❌ ollama container is not running."
        echo "   Start the stack first: ./manage.sh start"
        exit 1
    fi

    echo "   Target container: ollama"

    if docker exec ollama command -v nvidia-smi &>/dev/null; then
        echo "✅ NVIDIA container detected. Running nvidia-smi..."
        docker exec -it ollama nvidia-smi -l 1
        exit 0
    fi

    echo "ℹ️  Checking for AMD ROCm..."
    if ! docker exec ollama which rocm-smi &>/dev/null; then
        echo "⬇️  Installing rocm-smi inside container..."
        docker exec -u 0 ollama sh -c "apt-get update -qq && apt-get install -y -qq rocm-smi" || \
            echo "⚠️  Failed to install rocm-smi."
    fi

    echo "🟢 Starting AMD monitor... (Ctrl+C to exit)"
    docker exec -it ollama sh -c "while true; do clear; rocm-smi; sleep 1; done"
    ;;

  help|--help|-h)
    cat << EOF
Jarvis Stack Manager

Usage: ./manage.sh <command> [--cpu]

Start/Stop:
  start, up           Start the stack
  stop, down          Stop the stack
  restart             Restart the stack

Destructive:
  nuke, destroy       Delete stack AND all volumes (models, data, history)

Status & Logs:
  status, ps          Show container status
  logs                Stream all service logs (Ctrl+C to exit)
  logs-ollama         Stream Ollama logs only
  logs-webui          Stream Open WebUI logs only
  logs-tailscale      Stream Tailscale logs only
  monitor-gpu         Monitor GPU stats (NVIDIA or AMD)

Tailscale:
  serve-config        Show current Tailscale serve status and URLs

Version Info:
  versions            Show configured vs running image versions
  config              Show merged docker-compose configuration
  validate            Validate docker-compose.yaml syntax

Flags:
  --cpu               Force CPU-only mode (skip GPU detection)

Examples:
  ./manage.sh start           # Start stack (auto-detect GPU)
  ./manage.sh start --cpu     # Force CPU mode
  ./manage.sh logs            # Stream all logs
  ./manage.sh monitor-gpu     # Watch GPU usage
EOF
    ;;

  *)
    echo "Unknown command: $1"
    echo "Run './manage.sh help' for usage."
    exit 1
    ;;
esac

#!/bin/bash
# Jarvis Stack Manager - Easy commands to manage production and beta stacks
#
# Usage: ./manage.sh [command] [--cpu]

set -e

# Error handler for better diagnostics
trap 'echo "❌ Error on line $LINENO"; exit 1' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-detect container runtime (Podman vs Docker)
function detect_container_runtime() {
    # Skip if DOCKER_HOST is already set
    if [ -n "$DOCKER_HOST" ]; then
        return
    fi

    # Check for Podman's rootless socket first (common on Fedora/RHEL)
    local podman_socket="/run/user/$(id -u)/podman/podman.sock"
    if [ -S "$podman_socket" ]; then
        export DOCKER_HOST="unix://$podman_socket"
        echo "🐋 Using Podman (rootless socket)"
        return
    fi

    # Check for Podman's root socket
    if [ -S "/run/podman/podman.sock" ]; then
        export DOCKER_HOST="unix:///run/podman/podman.sock"
        echo "🐋 Using Podman (root socket)"
        return
    fi

    # Check for Docker's socket
    if [ -S "/var/run/docker.sock" ]; then
        echo "🐋 Using Docker"
        return
    fi

    # No socket found
    echo "❌ No container runtime socket found!"
    echo "   Please ensure Docker or Podman is running."
    echo ""
    echo "   For Podman (rootless), run:"
    echo "     systemctl --user enable --now podman.socket"
    echo ""
    echo "   For Docker, run:"
    echo "     sudo systemctl start docker"
    exit 1
}

# Detect container runtime before any docker commands
detect_container_runtime

# Load environment variables safely
# Note: Using standard 'set -a' parsing rather than 'xargs' to guard against space/shell metacharacter injection.
set -a
[ -f "$SCRIPT_DIR/production/.env" ] && source "$SCRIPT_DIR/production/.env"
[ -f "$SCRIPT_DIR/beta/.env" ] && source "$SCRIPT_DIR/beta/.env"
set +a

# Global Configuration
COMPOSE_FILES="-f docker-compose.yaml"

# Helper Functions

# Wait for Tailscale to be ready using a polling loop instead of a hardcoded sleep
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
}

function nuke_stack() {
    local stack_name=$1
    local data_desc=$2
    local command_str=$3
    echo "💥 WARNING: This will DELETE all volumes and data for $stack_name!"
    echo "$data_desc"
    read -p "Type 'yes' to confirm: " confirm
    if [ "$confirm" = "yes" ]; then
        echo "💣 Nuking $stack_name stack and volumes..."
        eval "$command_str"
        echo "✅ $stack_name stack and volumes destroyed!"
        echo "⚠️  $stack_name data is permanently gone."
    else
        echo "❌ Cancelled."
    fi
}

function detect_hardware() {
    # Check for --cpu override
    for arg in "$@"; do
        if [ "$arg" == "--cpu" ]; then
            echo "ℹ️  CPU mode forced by user request."
            return
        fi
    done

    # NVIDIA Check
    if command -v nvidia-smi &> /dev/null || [ -e /dev/nvidia0 ]; then
        echo "✅ NVIDIA GPU detected. Using NVIDIA configuration."
        COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.nvidia.yaml"
        return
    fi

    # AMD Check
    if [ -e /dev/kfd ]; then
        echo "✅ AMD GPU detected. Using AMD configuration."
        COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.amd.yaml"
        return
    fi

    echo "⚠️  No GPU detected. Falling back to CPU mode. Performance may be degraded."
}

function run_compose() {
    # echo "DEBUG: Running docker-compose $COMPOSE_FILES $@"
    docker-compose $COMPOSE_FILES "$@"
}

# Helper: Configure Tailscale Serve safely (avoiding redundant calls/throttling)
function configure_serve() {
    local container=$1
    local port=$2
    
    # Check if container exists (using docker inspect is more reliable)
    if ! docker inspect "$container" >/dev/null 2>&1; then
        return
    fi
    
    # Check if already serving
    if docker exec "$container" tailscale serve status 2>/dev/null | grep -q "http://127.0.0.1:$port"; then
        echo "✅ $container already serving on port $port"
        return
    fi
    
    echo "🔧 Configuring Tailscale Serve for $container..."
    docker exec "$container" tailscale serve --bg "http://127.0.0.1:$port" 2>/dev/null || echo "⚠️  Tailscale Serve config may need manual setup"
}

# Run detection
detect_hardware "$@"

# Command Handling
case "$1" in
  "")
    # No arguments - launch TUI if available
    if [ -f "$SCRIPT_DIR/tui.sh" ] && command -v dialog &> /dev/null; then
      exec "$SCRIPT_DIR/tui.sh"
    else
      echo "💡 Tip: Install 'dialog' for interactive TUI mode: sudo apt install dialog"
      echo ""
      exec "$SCRIPT_DIR/manage.sh" help
    fi
    ;;

  start|up)
    echo "🚀 Starting both production and beta stacks..."
    run_compose --profile all up -d
    echo "✅ Both stacks running!"
    echo ""
    run_compose --profile all ps
    echo ""
    wait_for_tailscale "tailscale-sidecar"
    wait_for_tailscale "tailscale-sidecar-beta"
    configure_serve "tailscale-sidecar" "8080"
    configure_serve "tailscale-sidecar-beta" "8081"
    echo "✅ Tailscale Serve configured!"
    ;;

  start-prod|up-prod)
    echo "🚀 Starting production stack only..."
    run_compose --profile prod up -d
    echo "✅ Production stack running!"
    echo ""
    wait_for_tailscale "tailscale-sidecar"
    configure_serve "tailscale-sidecar" "8080"
    ;;

  start-beta|up-beta)
    echo "🚀 Starting beta stack only..."
    echo "📥 Pulling latest beta image..."
    run_compose --profile beta pull open-webui-beta
    run_compose --profile beta up -d
    echo "✅ Beta stack running (using latest image)!"
    echo ""
    wait_for_tailscale "tailscale-sidecar-beta"
    configure_serve "tailscale-sidecar-beta" "8081"
    echo "✅ Beta Tailscale Serve configured!"
    ;;

  stop|down)
    echo "🛑 Stopping both stacks..."
    run_compose --profile all down
    echo "✅ Both stacks stopped!"
    ;;

  stop-prod|down-prod)
    echo "🛑 Stopping production stack..."
    # We use stop/rm here to target specific containers without needing profile flags if possible, 
    # taking advantage of compose knowing the services.
    run_compose stop open-webui2 tailscale-sidecar nginx-prod
    run_compose rm -f open-webui2 tailscale-sidecar nginx-prod
    echo "✅ Production stack stopped!"
    ;;

  stop-beta|down-beta)
    echo "🛑 Stopping beta stack..."
    run_compose stop open-webui-beta tailscale-sidecar-beta nginx-beta
    run_compose rm -f open-webui-beta tailscale-sidecar-beta nginx-beta
    echo "✅ Beta stack stopped!"
    ;;

  nuke|destroy)
    nuke_stack "BOTH" "Production and Beta data will be PERMANENTLY REMOVED" "run_compose --profile all down -v"
    ;;

  nuke-prod|destroy-prod)
    nuke_stack "PRODUCTION" "Production data will be PERMANENTLY REMOVED" "run_compose --profile prod down -v"
    ;;

  nuke-beta|destroy-beta)
    nuke_stack "BETA" "Beta data will be PERMANENTLY REMOVED" "run_compose --profile beta down -v"
    ;;

  restart)
    echo "🔄 Restarting both stacks..."
    run_compose --profile all restart
    echo "✅ Both stacks restarted!"
    echo ""
    wait_for_tailscale "tailscale-sidecar"
    wait_for_tailscale "tailscale-sidecar-beta"
    configure_serve "tailscale-sidecar" "8080"
    configure_serve "tailscale-sidecar-beta" "8081"
    echo "✅ Tailscale Serve reconfigured!"
    ;;

  restart-prod)
    echo "🔄 Restarting production stack..."
    run_compose restart open-webui2 tailscale-sidecar nginx-prod
    echo "✅ Production stack restarted!"
    echo ""
    wait_for_tailscale "tailscale-sidecar"
    configure_serve "tailscale-sidecar" "8080"
    echo "✅ Production Tailscale Serve reconfigured!"
    ;;

  restart-beta)
    echo "🔄 Restarting beta stack..."
    run_compose restart open-webui-beta tailscale-sidecar-beta nginx-beta
    echo "✅ Beta stack restarted!"
    echo ""
    wait_for_tailscale "tailscale-sidecar-beta"
    configure_serve "tailscale-sidecar-beta" "8081"
    echo "✅ Beta Tailscale Serve reconfigured!"
    ;;

  status|ps)
    echo "📊 Stack Status:"
    run_compose --profile all ps
    ;;

  logs)
    echo "📋 Logs (all stacks) - Press Ctrl+C to exit"
    run_compose --profile all logs -f
    ;;

  logs-prod)
    echo "📋 Production logs - Press Ctrl+C to exit"
    run_compose logs -f open-webui2 tailscale-sidecar nginx-prod
    ;;

  logs-beta)
    echo "📋 Beta logs - Press Ctrl+C to exit"
    run_compose logs -f open-webui-beta tailscale-sidecar-beta nginx-beta
    ;;

  config)
    echo "📝 Docker Compose Configuration:"
    run_compose --profile all config
    ;;

  validate)
    echo "✓ Validating docker-compose.yaml..."
    run_compose --profile all config > /dev/null
    echo "✅ Configuration is valid!"
    ;;

  help|--help|-h)
    cat << EOF
Jarvis Stack Manager

Usage: ./manage.sh <command> [--cpu]

Start/Stop Commands:
  start, up                 Start both production and beta stacks
  start-prod, up-prod       Start only production stack
  start-beta, up-beta       Start only beta stack
  stop, down                Stop both stacks
  stop-prod, down-prod      Stop only production stack
  stop-beta, down-beta      Stop only beta stack
  
Destructive Commands (WARNING - DELETES DATA):
  nuke, destroy             Delete all stacks AND volumes (both prod and beta)
  nuke-prod, destroy-prod   Delete production stack and all its data
  nuke-beta, destroy-beta   Delete beta stack and all its data
  
Restart Commands:
  restart                   Restart both stacks
  restart-prod              Restart only production stack
  restart-beta              Restart only beta stack

Tailscale Serve:
  serve-config              Configure Tailscale Serve for HTTPS access
  
View Commands:
  status, ps                Show status of all containers
  logs                      Show logs from all stacks (Ctrl+C to exit)
  logs-prod                 Show logs from production only
  logs-beta                 Show logs from beta only
  monitor-gpu               Monitor GPU stats (temps, power, internal usage)
  config                    Show merged docker-compose configuration
  validate                  Validate docker-compose.yaml syntax

Flags:
  --cpu                     Force CPU-only mode (ignore GPU even if present)

Version Management:
  versions                  Compare configured vs running image versions
  promote                   Promote beta's tested image to production

Other:
  help, --help, -h          Show this help message

Examples:
  ./manage.sh start           # Start both stacks (auto-detect GPU)
  ./manage.sh start --cpu     # Start both stacks in CPU mode
  ./manage.sh config          # See the generated GPU/CPU config
EOF
    ;;

  serve-config)
    echo "🔧 Configuring Tailscale Serve for both stacks..."
    docker exec tailscale-sidecar tailscale serve --bg http://127.0.0.1:8080 2>/dev/null || echo "Production Serve config may already be set"
    docker exec tailscale-sidecar-beta tailscale serve --bg http://127.0.0.1:8081 2>/dev/null || echo "Beta Serve config may already be set"
    echo "✅ Tailscale Serve configured!"
    echo ""
    echo "Available URLs (tailnet only):"
    echo "  Production: https://jarvis.YOUR_TAILNET.ts.net"
    echo "  Beta: https://jarvis-beta.YOUR_TAILNET.ts.net"
    echo ""
    echo "  (Replace YOUR_TAILNET with your actual Tailnet name)"
    ;;

  versions)
    echo "📊 Version Comparison:"
    echo ""
    # Extract image tags from docker-compose.yaml using service names (robust awk-based parsing)
    PROD_IMAGE=$(awk '/^  open-webui2:/{flag=1} flag && /image:/{gsub(/.*image:\s+/, ""); gsub(/\s+#.*/, ""); print; exit}' "$SCRIPT_DIR/docker-compose.yaml")
    BETA_IMAGE=$(awk '/^  open-webui-beta:/{flag=1} flag && /image:/{gsub(/.*image:\s+/, ""); gsub(/\s+#.*/, ""); print; exit}' "$SCRIPT_DIR/docker-compose.yaml")
    
    # Get running container images
    PROD_RUNNING=$(docker inspect open-webui2 --format='{{.Config.Image}}' 2>/dev/null || echo "Not running")
    BETA_RUNNING=$(docker inspect open-webui-beta --format='{{.Config.Image}}' 2>/dev/null || echo "Not running")
    
    echo "  Configured Images:"
    echo "    Production: $PROD_IMAGE"
    echo "    Beta:       $BETA_IMAGE"
    echo ""
    echo "  Running Images:"
    echo "    Production: $PROD_RUNNING"
    echo "    Beta:       $BETA_RUNNING"
    echo ""
    
    # Check if beta has newer version
    if [ "$PROD_IMAGE" != "$BETA_RUNNING" ] && [ "$BETA_RUNNING" != "Not running" ]; then
      echo "  💡 Tip: Run './manage.sh promote' to update production to beta's tested version."
    fi
    ;;

  monitor-gpu)
    echo "📊 GPU Monitor"
    
    # 1. Try host-level NVIDIA check first (fastest)
    if command -v nvidia-smi &> /dev/null; then
        echo "✅ NVIDIA host detected. Running nvidia-smi..."
        nvidia-smi -l 1
        exit 0
    fi

    # 2. Container-based check
    # Find a running Ollama container (beta or prod)
    CONTAINER=""
    if docker ps | grep -q "ollama-beta"; then
      CONTAINER="ollama-beta"
    elif docker ps | grep -q "ollama-prod"; then
      CONTAINER="ollama-prod"
    # Fallback for bundled open-webui containers (non-split architecture)
    elif docker ps | grep -q "open-webui-beta"; then
      CONTAINER="open-webui-beta"
    elif docker ps | grep -q "open-webui2"; then
      CONTAINER="open-webui2"
    fi
    
    if [ -z "$CONTAINER" ]; then
      echo "❌ No running GPU containers found."
      echo "   Start a stack first: ./manage.sh start-beta"
      exit 1
    fi
    
    echo "   Target container: $CONTAINER"
    
    # Check for NVIDIA inside container
    if docker exec $CONTAINER command -v nvidia-smi &>/dev/null; then
        echo "✅ NVIDIA container detected. Running nvidia-smi..."
        docker exec -it $CONTAINER nvidia-smi -l 1
        exit 0
    fi
    
    # Check for AMD/ROCm inside container
    echo "ℹ️  Checking for AMD ROCm..."
    
    # Check if rocm-smi is installed
    if ! docker exec $CONTAINER which rocm-smi &>/dev/null; then
      echo "⬇️  Installing rocm-smi inside container (one-time setup for AMD)..."
      docker exec -u 0 $CONTAINER sh -c "apt-get update -qq && apt-get install -y -qq rocm-smi" || echo "⚠️  Failed to install rocm-smi. Is this an Alpine container?"
    fi
    
    # Run AMD monitor
    echo "🟢 Starting AMD monitor... (Ctrl+C to exit)"
    # Use a loop since --watch isn't supported in all rocm-smi versions
    docker exec -it $CONTAINER sh -c "while true; do clear; rocm-smi; sleep 1; done"
    ;;

  promote)
    echo "🚀 Promote Beta Version to Production"
    echo ""
    
    # Get current beta image
    BETA_RUNNING=$(docker inspect open-webui-beta --format='{{.Config.Image}}' 2>/dev/null)
    if [ -z "$BETA_RUNNING" ] || [ "$BETA_RUNNING" == "" ]; then
      echo "❌ Beta container is not running. Start beta first with './manage.sh start-beta'"
      exit 1
    fi
    
    # Get the digest of the beta image for reproducibility
    BETA_DIGEST=$(docker inspect open-webui-beta --format='{{.Image}}' 2>/dev/null)
    
    echo "  Current Beta Image: $BETA_RUNNING"
    echo "  Current Beta Digest: ${BETA_DIGEST:0:19}..."
    echo ""
    
    # Get current production image (robust awk-based parsing)
    PROD_IMAGE=$(awk '/^  open-webui2:/{flag=1} flag && /image:/{gsub(/.*image:\s+/, ""); gsub(/\s+#.*/, ""); print; exit}' "$SCRIPT_DIR/docker-compose.yaml")
    echo "  Current Production Image: $PROD_IMAGE"
    echo ""
    
    if [ "$PROD_IMAGE" == "$BETA_RUNNING" ]; then
      echo "✅ Production is already running the same image as beta."
      exit 0
    fi
    
    echo "⚠️  This will update production to use: $BETA_RUNNING"
    read -p "Type 'yes' to confirm: " confirm
    if [ "$confirm" = "yes" ]; then
      # Update docker-compose.yaml (using awk to safely replace with special chars)
      awk -v prod="$PROD_IMAGE" -v beta="$BETA_RUNNING" \
        '{gsub("image: " prod, "image: " beta); print}' \
        "$SCRIPT_DIR/docker-compose.yaml" > "$SCRIPT_DIR/docker-compose.yaml.tmp" && \
        mv "$SCRIPT_DIR/docker-compose.yaml.tmp" "$SCRIPT_DIR/docker-compose.yaml"
      echo "✅ Updated docker-compose.yaml"
      echo ""
      echo "Next steps:"
      echo "  1. Review changes: git diff docker-compose.yaml"
      echo "  2. Restart production: ./manage.sh restart-prod"
      echo "  3. Commit: git add docker-compose.yaml && git commit -m 'chore: promote $(echo $BETA_RUNNING | cut -d: -f2) to production'"
    else
      echo "❌ Cancelled."
    fi
    ;;

  *)
    echo "Unknown command: $1"
    echo "Run './manage.sh help' for usage instructions"
    exit 1
    ;;
esac

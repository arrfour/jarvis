#!/bin/bash
# Jarvis Stack Manager - Easy commands to manage production and beta stacks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables from both production and beta
export $(cat "$SCRIPT_DIR/production/.env" 2>/dev/null | grep -v '^#' | xargs)
export $(cat "$SCRIPT_DIR/beta/.env" 2>/dev/null | grep -v '^#' | xargs)

case "$1" in
  start|up)
    echo "🚀 Starting both production and beta stacks..."
    docker-compose --profile all up -d
    echo "✅ Both stacks running!"
    echo ""
    docker-compose --profile all ps
    echo ""
    echo "⏳ Waiting for Tailscale to be ready..."
    sleep 5
    echo "🔧 Configuring Tailscale Serve..."
    docker exec tailscale-sidecar tailscale serve --bg http://127.0.0.1:8080 2>/dev/null
    docker exec tailscale-sidecar-beta tailscale serve --bg http://127.0.0.1:8081 2>/dev/null
    echo "✅ Tailscale Serve configured!"
    ;;

  start-prod|up-prod)
    echo "🚀 Starting production stack only..."
    docker-compose --profile prod up -d
    echo "✅ Production stack running!"
    ;;

  start-beta|up-beta)
    echo "🚀 Starting beta stack only..."
    docker-compose --profile beta up -d
    echo "✅ Beta stack running!"
    ;;

  stop|down)
    echo "🛑 Stopping both stacks..."
    docker-compose --profile all down
    echo "✅ Both stacks stopped!"
    ;;

  stop-prod|down-prod)
    echo "🛑 Stopping production stack..."
    docker-compose down open-webui2 tailscale-sidecar nginx-prod 2>/dev/null || docker-compose stop open-webui2 tailscale-sidecar nginx-prod
    echo "✅ Production stack stopped!"
    ;;

  stop-beta|down-beta)
    echo "🛑 Stopping beta stack..."
    docker-compose down open-webui-beta tailscale-sidecar-beta nginx-beta 2>/dev/null || docker-compose stop open-webui-beta tailscale-sidecar-beta nginx-beta
    echo "✅ Beta stack stopped!"
    ;;

  nuke|destroy)
    echo "💥 WARNING: This will DELETE all volumes and data for BOTH stacks!"
    echo "Production and Beta data will be PERMANENTLY REMOVED"
    read -p "Type 'yes' to confirm: " confirm
    if [ "$confirm" = "yes" ]; then
      echo "💣 Nuking both stacks and volumes..."
      docker-compose --profile all down -v
      echo "✅ Both stacks and all volumes destroyed!"
      echo "⚠️  All data is permanently gone. Run './manage.sh start' to recreate fresh."
    else
      echo "❌ Cancelled."
    fi
    ;;

  nuke-prod|destroy-prod)
    echo "💥 WARNING: This will DELETE all volumes and data for PRODUCTION!"
    echo "Production data will be PERMANENTLY REMOVED"
    read -p "Type 'yes' to confirm: " confirm
    if [ "$confirm" = "yes" ]; then
      echo "💣 Nuking production stack and volumes..."
      docker volume rm jarvis_ollama jarvis_open-webui jarvis_tailscale-sidecar-state 2>/dev/null || true
      docker-compose stop open-webui2 tailscale-sidecar nginx-prod 2>/dev/null || true
      echo "✅ Production stack and volumes destroyed!"
      echo "⚠️  Production data is permanently gone. Run './manage.sh start-prod' to recreate fresh."
    else
      echo "❌ Cancelled."
    fi
    ;;

  nuke-beta|destroy-beta)
    echo "💥 WARNING: This will DELETE all volumes and data for BETA!"
    echo "Beta data will be PERMANENTLY REMOVED"
    read -p "Type 'yes' to confirm: " confirm
    if [ "$confirm" = "yes" ]; then
      echo "💣 Nuking beta stack and volumes..."
      docker volume rm jarvis_ollama-beta jarvis_open-webui-beta jarvis_tailscale-sidecar-beta-state 2>/dev/null || true
      docker-compose stop open-webui-beta tailscale-sidecar-beta nginx-beta 2>/dev/null || true
      echo "✅ Beta stack and volumes destroyed!"
      echo "⚠️  Beta data is permanently gone. Run './manage.sh start-beta' to recreate fresh."
    else
      echo "❌ Cancelled."
    fi
    ;;

  restart)
    echo "🔄 Restarting both stacks..."
    docker-compose --profile all restart
    echo "✅ Both stacks restarted!"
    echo ""
    echo "⏳ Waiting for Tailscale to be ready..."
    sleep 5
    echo "🔧 Reconfiguring Tailscale Serve..."
    docker exec tailscale-sidecar tailscale serve --bg http://127.0.0.1:8080 2>/dev/null
    docker exec tailscale-sidecar-beta tailscale serve --bg http://127.0.0.1:8081 2>/dev/null
    echo "✅ Tailscale Serve reconfigured!"
    ;;

  restart-prod)
    echo "🔄 Restarting production stack..."
    docker-compose restart open-webui2 tailscale-sidecar nginx-prod
    echo "✅ Production stack restarted!"
    echo ""
    echo "⏳ Waiting for Tailscale to be ready..."
    sleep 3
    echo "🔧 Reconfiguring Tailscale Serve for production..."
    docker exec tailscale-sidecar tailscale serve --bg http://127.0.0.1:8080 2>/dev/null
    echo "✅ Production Tailscale Serve reconfigured!"
    ;;

  restart-beta)
    echo "🔄 Restarting beta stack..."
    docker-compose restart open-webui-beta tailscale-sidecar-beta nginx-beta
    echo "✅ Beta stack restarted!"
    echo ""
    echo "⏳ Waiting for Tailscale to be ready..."
    sleep 3
    echo "🔧 Reconfiguring Tailscale Serve for beta..."
    docker exec tailscale-sidecar-beta tailscale serve --bg http://127.0.0.1:8081 2>/dev/null
    echo "✅ Beta Tailscale Serve reconfigured!"
    ;;

  status|ps)
    echo "📊 Stack Status:"
    docker-compose --profile all ps
    ;;

  logs)
    echo "📋 Logs (all stacks) - Press Ctrl+C to exit"
    docker-compose --profile all logs -f
    ;;

  logs-prod)
    echo "📋 Production logs - Press Ctrl+C to exit"
    docker-compose logs -f open-webui2 tailscale-sidecar nginx-prod
    ;;

  logs-beta)
    echo "📋 Beta logs - Press Ctrl+C to exit"
    docker-compose logs -f open-webui-beta tailscale-sidecar-beta nginx-beta
    ;;

  config)
    echo "📝 Docker Compose Configuration:"
    docker-compose --profile all config
    ;;

  validate)
    echo "✓ Validating docker-compose.yaml..."
    docker-compose --profile all config > /dev/null
    echo "✅ Configuration is valid!"
    ;;

  help|--help|-h)
    cat << EOF
Jarvis Stack Manager

Usage: ./manage.sh <command>

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
  config                    Show merged docker-compose configuration
  validate                  Validate docker-compose.yaml syntax

Other:
  help, --help, -h          Show this help message

Examples:
  ./manage.sh start           # Start both stacks
  ./manage.sh stop            # Stop both stacks
  ./manage.sh restart-beta    # Restart only beta stack
  ./manage.sh logs-prod       # View production logs
  ./manage.sh status          # Check status of all containers
  ./manage.sh nuke-beta       # Delete all beta data (asks for confirmation)

EOF
    ;;

  serve-config)
    echo "🔧 Configuring Tailscale Serve for both stacks..."
    docker exec tailscale-sidecar tailscale serve --bg http://127.0.0.1:8080 2>/dev/null || echo "Production Serve config may already be set"
    docker exec tailscale-sidecar-beta tailscale serve --bg http://127.0.0.1:8081 2>/dev/null || echo "Beta Serve config may already be set"
    echo "✅ Tailscale Serve configured!"
    echo ""
    echo "Available URLs (tailnet only):"
    echo "  Production: https://jarvis.tailcd013.ts.net"
    echo "  Beta: https://jarvis-beta.tailcd013.ts.net"
    ;;

  *)
    echo "Unknown command: $1"
    echo "Run './manage.sh help' for usage instructions"
    exit 1
    ;;
esac

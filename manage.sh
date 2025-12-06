#!/bin/bash
# Jarvis Stack Manager - Easy commands to manage production and beta stacks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$1" in
  start|up)
    echo "🚀 Starting both production and beta stacks..."
    docker compose up -d
    echo "✅ Both stacks running!"
    echo ""
    docker compose ps
    ;;

  start-prod|up-prod)
    echo "🚀 Starting production stack only..."
    docker compose up -d --profile prod
    echo "✅ Production stack running!"
    ;;

  start-beta|up-beta)
    echo "🚀 Starting beta stack only..."
    docker compose up -d --profile beta
    echo "✅ Beta stack running!"
    ;;

  stop|down)
    echo "🛑 Stopping both stacks..."
    docker compose down
    echo "✅ Both stacks stopped!"
    ;;

  restart)
    echo "🔄 Restarting both stacks..."
    docker compose restart
    echo "✅ Both stacks restarted!"
    ;;

  restart-prod)
    echo "🔄 Restarting production stack..."
    docker compose restart open-webui2 tailscale-sidecar nginx-prod
    echo "✅ Production stack restarted!"
    ;;

  restart-beta)
    echo "🔄 Restarting beta stack..."
    docker compose restart open-webui-beta tailscale-sidecar-beta nginx-beta
    echo "✅ Beta stack restarted!"
    ;;

  status|ps)
    echo "📊 Stack Status:"
    docker compose ps
    ;;

  logs)
    echo "📋 Logs (all stacks) - Press Ctrl+C to exit"
    docker compose logs -f
    ;;

  logs-prod)
    echo "📋 Production logs - Press Ctrl+C to exit"
    docker compose logs -f open-webui2 tailscale-sidecar nginx-prod
    ;;

  logs-beta)
    echo "📋 Beta logs - Press Ctrl+C to exit"
    docker compose logs -f open-webui-beta tailscale-sidecar-beta nginx-beta
    ;;

  config)
    echo "📝 Docker Compose Configuration:"
    docker compose config
    ;;

  validate)
    echo "✓ Validating docker-compose.yaml..."
    docker compose config > /dev/null
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
  
Restart Commands:
  restart                   Restart both stacks
  restart-prod              Restart only production stack
  restart-beta              Restart only beta stack

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
  ./manage.sh restart-beta    # Restart only beta stack
  ./manage.sh logs-prod       # View production logs
  ./manage.sh status          # Check status of all containers

EOF
    ;;

  *)
    echo "Unknown command: $1"
    echo "Run './manage.sh help' for usage instructions"
    exit 1
    ;;
esac

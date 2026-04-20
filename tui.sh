#!/bin/bash
# Jarvis TUI Manager - Interactive Terminal User Interface
#
# Uses 'dialog' for rich TUI experience.
# Falls back to manage.sh help for CLI operations.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANAGE_SCRIPT="$SCRIPT_DIR/manage.sh"

run_compose() {
    if docker compose version &>/dev/null 2>&1; then
        docker compose "$@"
    elif command -v docker-compose &>/dev/null; then
        docker-compose "$@"
    else
        echo "Docker Compose is not installed"
        return 1
    fi
}

# Dialog dimensions
DIALOG_HEIGHT=20
DIALOG_WIDTH=60
MENU_HEIGHT=10

check_dialog() {
    if ! command -v dialog &> /dev/null; then
        echo "Error: 'dialog' is not installed."
        echo "Install it with: sudo apt install dialog"
        echo ""
        echo "Falling back to CLI mode..."
        exec "$MANAGE_SCRIPT" help
    fi
}

get_status_icon() {
    local container=$1
    local status
    status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "not_found")
    case "$status" in
        running)            echo "🟢" ;;
        exited)             echo "🔴" ;;
        created|restarting) echo "🟡" ;;
        *)                  echo "⚪" ;;
    esac
}

detect_mode() {
    if command -v nvidia-smi &> /dev/null || [ -e /dev/nvidia0 ]; then
        echo "\Z2🟢 NVIDIA GPU Mode\Zn"
    elif [ -e /dev/kfd ]; then
        echo "\Z1🔴 AMD GPU Mode\Zn"
    else
        echo "\Z3⚪ CPU Mode\Zn"
    fi
}

get_health_summary() {
    local output=""
    output+="Mode: $(detect_mode)\n"
    output+="━━━━━━━━━━━━━━━━━━\n"
    output+="$(get_status_icon ollama) ollama\n"
    output+="$(get_status_icon open-webui) open-webui\n"
    output+="$(get_status_icon nginx) nginx\n"
    output+="$(get_status_icon tailscale) tailscale\n"
    echo -e "$output"
}

show_status_dashboard() {
    local status_info
    status_info=$(run_compose -f "$SCRIPT_DIR/docker-compose.yaml" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers running")
    dialog --title "📊 Stack Status Dashboard" \
           --msgbox "$status_info\n\n$(get_health_summary)" \
           $DIALOG_HEIGHT $((DIALOG_WIDTH + 20))
}

logs_menu() {
    local choice
    choice=$(dialog --title "📋 View Logs" \
                    --menu "Select which logs to view:" \
                    $DIALOG_HEIGHT $DIALOG_WIDTH $MENU_HEIGHT \
                    "1" "All Services (live streaming)" \
                    "2" "Ollama only" \
                    "3" "Open WebUI only" \
                    "4" "Tailscale only" \
                    "5" "← Back to Main Menu" \
                    3>&1 1>&2 2>&3) || true

    clear
    case "$choice" in
        1)
            echo "📋 Streaming all logs (Ctrl+C to return)..."
            "$MANAGE_SCRIPT" logs || true
            ;;
        2)
            echo "📋 Streaming Ollama logs (Ctrl+C to return)..."
            "$MANAGE_SCRIPT" logs-ollama || true
            ;;
        3)
            echo "📋 Streaming Open WebUI logs (Ctrl+C to return)..."
            "$MANAGE_SCRIPT" logs-webui || true
            ;;
        4)
            echo "📋 Streaming Tailscale logs (Ctrl+C to return)..."
            "$MANAGE_SCRIPT" logs-tailscale || true
            ;;
        5|"") return ;;
    esac
}

config_menu() {
    local choice
    choice=$(dialog --title "⚙️ Configuration" \
                    --menu "Select an action:" \
                    $DIALOG_HEIGHT $DIALOG_WIDTH $MENU_HEIGHT \
                    "1" "View Docker Compose Config" \
                    "2" "Validate Configuration" \
                    "3" "Tailscale Serve Status" \
                    "4" "Image Versions" \
                    "5" "← Back to Main Menu" \
                    3>&1 1>&2 2>&3) || true

    case "$choice" in
        1) run_with_output "config" ;;
        2) run_with_output "validate" ;;
        3) run_with_output "serve-config" ;;
        4) run_with_output "versions" ;;
        5|"") return ;;
    esac
}

destructive_menu() {
    local choice
    choice=$(dialog --title "💥 Destructive Operations" \
                    --colors \
                    --menu "\Z1WARNING: These operations DELETE DATA!\Zn\n\nSelect carefully:" \
                    $DIALOG_HEIGHT $DIALOG_WIDTH $MENU_HEIGHT \
                    "1" "🔥 Nuke EVERYTHING (Stack + All Data)" \
                    "2" "← Back to Main Menu (Safe)" \
                    3>&1 1>&2 2>&3) || true

    case "$choice" in
        1)
            if dialog --title "💥 FINAL WARNING" \
                      --colors \
                      --yesno "\Z1This will PERMANENTLY DELETE:\Zn\n\n• Stack (all containers)\n• Ollama models\n• Open WebUI data\n• Conversation history\n\nType 'yes' to confirm in the next step.\n\nContinue?" \
                      15 55; then
                clear
                "$MANAGE_SCRIPT" nuke
                read -p "Press Enter to continue..."
            fi
            ;;
        2|"") return ;;
    esac
}

run_with_output() {
    local cmd=$1
    clear
    echo "Running: ./manage.sh $cmd"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    "$MANAGE_SCRIPT" "$cmd" 2>&1
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -p "Press Enter to continue..."
}

main_menu() {
    while true; do
        local choice exit_status
        set +e
        choice=$(dialog --title "🤖 Jarvis Stack Manager" \
                        --colors \
                        --menu "$(get_health_summary)\n\nSelect an action:" \
                        $((DIALOG_HEIGHT + 5)) $DIALOG_WIDTH $MENU_HEIGHT \
                        "1" "🚀 Start Stack" \
                        "2" "🛑 Stop Stack" \
                        "3" "🔄 Restart Stack" \
                        "4" "📊 Status Dashboard" \
                        "5" "📈 GPU Monitor" \
                        "6" "📋 View Logs" \
                        "7" "⚙️  Configuration" \
                        "8" "💥 Destructive Operations" \
                        "9" "❓ Help" \
                        "0" "🚪 Exit" \
                        3>&1 1>&2 2>&3)
        exit_status=$?
        set -e

        if [ $exit_status -eq 1 ] || [ $exit_status -eq 255 ]; then
            clear
            echo "👋 Goodbye!"
            exit 0
        elif [ $exit_status -ne 0 ]; then
            echo "❌ Dialog error (exit code: $exit_status)"
            exit 1
        fi

        case "$choice" in
            1) run_with_output "start" ;;
            2) run_with_output "stop" ;;
            3) run_with_output "restart" ;;
            4) show_status_dashboard ;;
            5)
                clear
                "$MANAGE_SCRIPT" monitor-gpu || true
                read -p "Press Enter to continue..."
                ;;
            6) logs_menu ;;
            7) config_menu ;;
            8) destructive_menu ;;
            9) run_with_output "help" ;;
            0)
                clear
                echo "👋 Goodbye!"
                exit 0
                ;;
        esac
    done
}

check_dialog
main_menu

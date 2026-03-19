#!/bin/bash
# Jarvis TUI Manager - Interactive Terminal User Interface
# 
# Uses 'dialog' for rich TUI experience
# Falls back to manage.sh for CLI operations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANAGE_SCRIPT="$SCRIPT_DIR/manage.sh"

# Colors for status indicators
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Dialog dimensions
DIALOG_HEIGHT=20
DIALOG_WIDTH=60
MENU_HEIGHT=12

# Check for dialog
check_dialog() {
    if ! command -v dialog &> /dev/null; then
        echo "Error: 'dialog' is not installed."
        echo "Install it with: sudo apt install dialog"
        echo ""
        echo "Falling back to CLI mode..."
        exec "$MANAGE_SCRIPT" help
    fi
}

# Get container status with icon
get_status_icon() {
    local container=$1
    local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "not_found")
    
    case "$status" in
        running)  echo "🟢" ;;
        exited)   echo "🔴" ;;
        starting) echo "🟡" ;;
        *)        echo "⚪" ;;
    esac
}

# Get container health summary
# Detect Hardware Mode
detect_mode() {
    if command -v nvidia-smi &> /dev/null || [ -e /dev/nvidia0 ]; then
        echo "\Z2🟢 NVIDIA GPU Mode\Zn"
    elif [ -e /dev/kfd ]; then
        echo "\Z1🔴 AMD GPU Mode\Zn"
    else
        echo "\Z3⚪ CPU Mode\Zn"
    fi
}

# Get health summary
get_health_summary() {
    local output=""
    
    # Mode Header
    output+="Mode: $(detect_mode)\n"
    output+="━━━━━━━━━━━━━━━━━━\n"
    
    # Production containers
    output+="━━━ PRODUCTION ━━━\n"
    output+="$(get_status_icon open-webui2) open-webui2\n"
    output+="$(get_status_icon tailscale-sidecar) tailscale-sidecar\n"
    output+="$(get_status_icon nginx-prod) nginx-prod\n"
    output+="\n"
    
    # Beta containers
    output+="━━━ BETA ━━━\n"
    output+="$(get_status_icon open-webui-beta) open-webui-beta\n"
    output+="$(get_status_icon tailscale-sidecar-beta) tailscale-sidecar-beta\n"
    output+="$(get_status_icon nginx-beta) nginx-beta\n"
    
    echo -e "$output"
}

# Show status dashboard
show_status_dashboard() {
    local status_info
    status_info=$(docker compose -f "$SCRIPT_DIR/docker-compose.yaml" --profile all ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers running")
    
    dialog --title "📊 Stack Status Dashboard" \
           --msgbox "$status_info\n\n$(get_health_summary)" \
           $DIALOG_HEIGHT $((DIALOG_WIDTH + 20))
}

# Start stacks submenu
start_menu() {
    local choice
    choice=$(dialog --title "🚀 Start Stacks" \
                    --menu "Select which stack(s) to start:" \
                    $DIALOG_HEIGHT $DIALOG_WIDTH $MENU_HEIGHT \
                    "1" "Start Both (Production + Beta)" \
                    "2" "Start Production Only" \
                    "3" "Start Beta Only" \
                    "4" "← Back to Main Menu" \
                    3>&1 1>&2 2>&3)
    
    case "$choice" in
        1) run_with_output "start" ;;
        2) run_with_output "start-prod" ;;
        3) run_with_output "start-beta" ;;
        4|"") return ;;
    esac
}

# Stop stacks submenu
stop_menu() {
    local choice
    choice=$(dialog --title "🛑 Stop Stacks" \
                    --menu "Select which stack(s) to stop:" \
                    $DIALOG_HEIGHT $DIALOG_WIDTH $MENU_HEIGHT \
                    "1" "Stop Both (Production + Beta)" \
                    "2" "Stop Production Only" \
                    "3" "Stop Beta Only" \
                    "4" "← Back to Main Menu" \
                    3>&1 1>&2 2>&3)
    
    case "$choice" in
        1) run_with_output "stop" ;;
        2) run_with_output "stop-prod" ;;
        3) run_with_output "stop-beta" ;;
        4|"") return ;;
    esac
}

# Restart stacks submenu
restart_menu() {
    local choice
    choice=$(dialog --title "🔄 Restart Stacks" \
                    --menu "Select which stack(s) to restart:" \
                    $DIALOG_HEIGHT $DIALOG_WIDTH $MENU_HEIGHT \
                    "1" "Restart Both (Production + Beta)" \
                    "2" "Restart Production Only" \
                    "3" "Restart Beta Only" \
                    "4" "← Back to Main Menu" \
                    3>&1 1>&2 2>&3)
    
    case "$choice" in
        1) run_with_output "restart" ;;
        2) run_with_output "restart-prod" ;;
        3) run_with_output "restart-beta" ;;
        4|"") return ;;
    esac
}

# Logs submenu
logs_menu() {
    local choice
    choice=$(dialog --title "📋 View Logs" \
                    --menu "Select which logs to view:" \
                    $DIALOG_HEIGHT $DIALOG_WIDTH $MENU_HEIGHT \
                    "1" "All Stacks (live streaming)" \
                    "2" "Production Only (live streaming)" \
                    "3" "Beta Only (live streaming)" \
                    "4" "← Back to Main Menu" \
                    3>&1 1>&2 2>&3)
    
    clear
    case "$choice" in
        1) 
            echo "📋 Streaming all logs (Ctrl+C to return)..."
            "$MANAGE_SCRIPT" logs || true
            ;;
        2) 
            echo "📋 Streaming production logs (Ctrl+C to return)..."
            "$MANAGE_SCRIPT" logs-prod || true
            ;;
        3) 
            echo "📋 Streaming beta logs (Ctrl+C to return)..."
            "$MANAGE_SCRIPT" logs-beta || true
            ;;
        4|"") return ;;
    esac
}

# Version management submenu
version_menu() {
    local choice
    choice=$(dialog --title "📦 Version Management" \
                    --menu "Select an action:" \
                    $DIALOG_HEIGHT $DIALOG_WIDTH $MENU_HEIGHT \
                    "1" "View Current Versions" \
                    "2" "Promote Beta to Production" \
                    "3" "← Back to Main Menu" \
                    3>&1 1>&2 2>&3)
    
    case "$choice" in
        1) run_with_output "versions" ;;
        2) 
            if dialog --title "⚠️ Confirm Promotion" \
                      --yesno "This will update production to use the same image as beta.\n\nProceed?" \
                      10 50; then
                clear
                echo "yes" | "$MANAGE_SCRIPT" promote
                echo ""
                read -p "Press Enter to continue..."
            fi
            ;;
        3|"") return ;;
    esac
}

# Configuration submenu
config_menu() {
    local choice
    choice=$(dialog --title "⚙️ Configuration" \
                    --menu "Select an action:" \
                    $DIALOG_HEIGHT $DIALOG_WIDTH $MENU_HEIGHT \
                    "1" "View Docker Compose Config" \
                    "2" "Validate Configuration" \
                    "3" "Configure Tailscale Serve" \
                    "4" "← Back to Main Menu" \
                    3>&1 1>&2 2>&3)
    
    case "$choice" in
        1) run_with_output "config" ;;
        2) run_with_output "validate" ;;
        3) run_with_output "serve-config" ;;
        4|"") return ;;
    esac
}

# Destructive operations submenu
destructive_menu() {
    local choice
    choice=$(dialog --title "💥 Destructive Operations" \
                    --colors \
                    --menu "\Z1WARNING: These operations DELETE DATA!\Zn\n\nSelect carefully:" \
                    $DIALOG_HEIGHT $DIALOG_WIDTH $MENU_HEIGHT \
                    "1" "🔥 Nuke EVERYTHING (Both Stacks + Data)" \
                    "2" "🔥 Nuke Production (Stack + Data)" \
                    "3" "🔥 Nuke Beta (Stack + Data)" \
                    "4" "← Back to Main Menu (Safe)" \
                    3>&1 1>&2 2>&3)
    
    case "$choice" in
        1)
            if dialog --title "💥 FINAL WARNING" \
                      --colors \
                      --yesno "\Z1This will PERMANENTLY DELETE:\Zn\n\n• Both Production and Beta stacks\n• ALL volumes and data\n• ALL conversation history\n\nType 'yes' to confirm in the next step.\n\nContinue?" \
                      15 55; then
                clear
                "$MANAGE_SCRIPT" nuke
                read -p "Press Enter to continue..."
            fi
            ;;
        2)
            if dialog --title "💥 FINAL WARNING" \
                      --colors \
                      --yesno "\Z1This will PERMANENTLY DELETE:\Zn\n\n• Production stack\n• Production volumes and data\n\nType 'yes' to confirm in the next step.\n\nContinue?" \
                      14 55; then
                clear
                "$MANAGE_SCRIPT" nuke-prod
                read -p "Press Enter to continue..."
            fi
            ;;
        3)
            if dialog --title "💥 FINAL WARNING" \
                      --colors \
                      --yesno "\Z1This will PERMANENTLY DELETE:\Zn\n\n• Beta stack\n• Beta volumes and data\n\nType 'yes' to confirm in the next step.\n\nContinue?" \
                      14 55; then
                clear
                "$MANAGE_SCRIPT" nuke-beta
                read -p "Press Enter to continue..."
            fi
            ;;
        4|"") return ;;
    esac
}

# Run manage.sh command and show output in dialog
run_with_output() {
    local cmd=$1
    local output
    
    clear
    echo "Running: ./manage.sh $cmd"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    TMP_OUTPUT=$(mktemp /tmp/jarvis_tui_output.XXXXXX)
    "$MANAGE_SCRIPT" "$cmd" 2>&1 | tee "$TMP_OUTPUT"
    rm -f "$TMP_OUTPUT"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -p "Press Enter to continue..."
}

# Main menu
main_menu() {
    while true; do
        local choice
        choice=$(dialog --title "🤖 Jarvis Stack Manager" \
                        --colors \
                        --menu "$(get_health_summary)\n\nSelect an action:" \
                        $((DIALOG_HEIGHT + 5)) $DIALOG_WIDTH $MENU_HEIGHT \
                        "1" "🚀 Start Stacks" \
                        "2" "🛑 Stop Stacks" \
                        "3" "🔄 Restart Stacks" \
                        "4" "📊 Status Dashboard" \
                        "5" "📈 GPU Monitor" \
                        "6" "📋 View Logs" \
                        "7" "📦 Version Management" \
                        "8" "⚙️  Configuration" \
                        "9" "💥 Destructive Operations" \
                        "10" "❓ Help" \
                        "0" "🚪 Exit" \
                        3>&1 1>&2 2>&3)
        
        local exit_status=$?
        
        # Handle ESC or Cancel
        if [ $exit_status -ne 0 ]; then
            clear
            echo "👋 Goodbye!"
            exit 0
        fi
        
        case "$choice" in
            1) start_menu ;;
            2) stop_menu ;;
            3) restart_menu ;;
            4) show_status_dashboard ;;
            5) 
                clear
                "$MANAGE_SCRIPT" monitor-gpu || true
                read -p "Press Enter to continue..."
                ;;
            6) logs_menu ;;
            7) version_menu ;;
            8) config_menu ;;
            9) destructive_menu ;;
            10) run_with_output "help" ;;
            0) 
                clear
                echo "👋 Goodbye!"
                exit 0
                ;;
        esac
    done
}

# Entry point
check_dialog
main_menu

# Jarvis Ansible Makefile
# Provides convenient shortcuts for common Ansible operations
#
# Usage:
#   make install      # Install Ansible requirements (one-time)
#   make setup        # Verify prerequisites
#   make validate     # Validate configuration
#   make start        # Start both stacks
#   make stop         # Stop both stacks
#   make restart      # Restart both stacks
#   make status       # Show status
#   make help         # Show this help

.PHONY: help install setup validate start stop restart status start-prod start-beta stop-prod stop-beta restart-prod restart-beta logs

# Default target
.DEFAULT_GOAL := help

# Ansible command
ANSIBLE_PLAYBOOK := ansible-playbook
SITE_PLAYBOOK := playbooks/site.yml

help: ## Show this help message
	@echo "Jarvis Ansible Stack Management"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Setup:"
	@echo "  install       Install Ansible Galaxy requirements (one-time)"
	@echo "  setup         Verify prerequisites (Docker, etc.)"
	@echo "  validate      Validate environment and configuration"
	@echo ""
	@echo "Stack Operations:"
	@echo "  start         Start both production and beta stacks"
	@echo "  stop          Stop both stacks"
	@echo "  restart       Restart both stacks"
	@echo ""
	@echo "Individual Stack Operations:"
	@echo "  start-prod    Start production stack only"
	@echo "  start-beta    Start beta stack only"
	@echo "  stop-prod     Stop production stack only"
	@echo "  stop-beta     Stop beta stack only"
	@echo "  restart-prod  Restart production stack only"
	@echo "  restart-beta  Restart beta stack only"
	@echo ""
	@echo "Monitoring:"
	@echo "  status        Show container status"
	@echo "  logs          Show recent logs"
	@echo ""
	@echo "Examples:"
	@echo "  make install      # First-time setup"
	@echo "  make start        # Start everything"
	@echo "  make restart-beta # Restart only beta"
	@echo "  make status       # Check what's running"

install: ## Install Ansible Galaxy requirements
	@echo "📦 Installing Ansible Galaxy requirements..."
	ansible-galaxy install -r requirements.yml

setup: ## Verify prerequisites
	@echo "🔍 Verifying prerequisites..."
	$(ANSIBLE_PLAYBOOK) $(SITE_PLAYBOOK) --tags setup

validate: ## Validate configuration
	@echo "✓ Validating configuration..."
	$(ANSIBLE_PLAYBOOK) $(SITE_PLAYBOOK) --tags validate

start: ## Start both stacks
	@echo "🚀 Starting both stacks..."
	$(ANSIBLE_PLAYBOOK) playbooks/start.yml

stop: ## Stop both stacks
	@echo "🛑 Stopping both stacks..."
	$(ANSIBLE_PLAYBOOK) playbooks/stop.yml

restart: ## Restart both stacks
	@echo "🔄 Restarting both stacks..."
	$(ANSIBLE_PLAYBOOK) playbooks/restart.yml

start-prod: ## Start production stack only
	@echo "🚀 Starting production stack..."
	$(ANSIBLE_PLAYBOOK) $(SITE_PLAYBOOK) --tags start-prod

start-beta: ## Start beta stack only
	@echo "🚀 Starting beta stack..."
	$(ANSIBLE_PLAYBOOK) $(SITE_PLAYBOOK) --tags start-beta

stop-prod: ## Stop production stack only
	@echo "🛑 Stopping production stack..."
	$(ANSIBLE_PLAYBOOK) $(SITE_PLAYBOOK) --tags stop-prod

stop-beta: ## Stop beta stack only
	@echo "🛑 Stopping beta stack..."
	$(ANSIBLE_PLAYBOOK) $(SITE_PLAYBOOK) --tags stop-beta

restart-prod: ## Restart production stack only
	@echo "🔄 Restarting production stack..."
	$(ANSIBLE_PLAYBOOK) $(SITE_PLAYBOOK) --tags restart-prod

restart-beta: ## Restart beta stack only
	@echo "🔄 Restarting beta stack..."
	$(ANSIBLE_PLAYBOOK) $(SITE_PLAYBOOK) --tags restart-beta

status: ## Show stack status
	@echo "📊 Stack status:"
	$(ANSIBLE_PLAYBOOK) playbooks/status.yml

logs: ## Show recent logs
	@echo "📋 Recent logs:"
	$(ANSIBLE_PLAYBOOK) $(SITE_PLAYBOOK) --tags logs

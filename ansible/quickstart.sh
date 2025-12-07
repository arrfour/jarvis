#!/bin/bash
# Quick start script for Ansible setup
# This script helps new users set up Ansible for the first time
#
# Usage: ./quickstart.sh
# Note: If this script is not executable, run: chmod +x quickstart.sh

set -e

echo "🚀 Jarvis Ansible Quick Start"
echo ""

# Check if we're in the ansible directory
if [ ! -f "ansible.cfg" ]; then
    if [ -d "ansible" ]; then
        cd ansible
        echo "📁 Changed to ansible directory"
    else
        echo "❌ Error: ansible directory not found"
        echo "   Please run this script from the project root or ansible directory"
        exit 1
    fi
fi

echo "Step 1: Checking for Ansible..."
if command -v ansible-playbook &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n 1)
    echo "✅ $ANSIBLE_VERSION"
else
    echo "❌ Ansible is not installed"
    echo ""
    echo "Install Ansible with one of these methods:"
    echo ""
    echo "  Ubuntu/Debian:"
    echo "    sudo apt update && sudo apt install ansible -y"
    echo ""
    echo "  Using pip:"
    echo "    pip3 install ansible"
    echo ""
    echo "  macOS:"
    echo "    brew install ansible"
    echo ""
    exit 1
fi

echo ""
echo "Step 2: Installing Ansible Galaxy requirements..."
if ansible-galaxy install -r requirements.yml; then
    echo "✅ Requirements installed successfully"
else
    echo "❌ Failed to install requirements"
    exit 1
fi

echo ""
echo "Step 3: Verifying prerequisites..."
if ansible-playbook playbooks/site.yml --tags setup; then
    echo "✅ Prerequisites verified"
else
    echo "⚠️  Some prerequisites may be missing (see above)"
fi

echo ""
echo "Step 4: Validating configuration..."
if ansible-playbook playbooks/site.yml --tags validate; then
    echo "✅ Configuration is valid"
else
    echo "⚠️  Configuration validation failed (see above)"
    echo ""
    echo "Common issues:"
    echo "  - Missing .env files: cp production/.env.example production/.env"
    echo "  - Missing auth keys: Edit .env files and add TS_AUTHKEY values"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ Ansible setup complete!"
echo ""
echo "You can now use Ansible to manage your stacks:"
echo ""
echo "  Using Makefile (recommended):"
echo "    make start        # Start both stacks"
echo "    make status       # Check status"
echo "    make restart-beta # Restart beta only"
echo "    make help         # Show all commands"
echo ""
echo "  Using ansible-playbook directly:"
echo "    ansible-playbook playbooks/start.yml"
echo "    ansible-playbook playbooks/status.yml"
echo ""
echo "  Quick reference:"
echo "    cd ansible"
echo "    make help         # See all available commands"
echo ""
echo "For more information, see ansible/README.md"
echo "═══════════════════════════════════════════════════════"

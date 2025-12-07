# Jarvis Ansible Stack Management

This directory contains Ansible playbooks and roles for managing the Jarvis production and beta stacks. Ansible provides an infrastructure-as-code approach that works alongside the existing `manage.sh` bash script.

## 📋 Overview

The Ansible implementation provides:
- ✅ **Idempotent operations** - Safe to run multiple times
- ✅ **Infrastructure as Code** - Version-controlled configuration
- ✅ **Declarative syntax** - Describe desired state, not steps
- ✅ **Parallel execution** - Efficient operations across hosts
- ✅ **Detailed logging** - Clear output for debugging
- ✅ **Non-breaking** - Works alongside existing bash scripts

## 🚀 Quick Start

### Prerequisites

```bash
# Install Ansible (Ubuntu/Debian)
sudo apt update
sudo apt install ansible -y

# Or using pip
pip3 install ansible

# Verify installation
ansible --version
```

### One-Time Setup

```bash
cd ansible

# Install required Ansible collections
ansible-galaxy install -r requirements.yml

# Verify prerequisites (Docker, Docker Compose, directories)
ansible-playbook playbooks/site.yml --tags setup
```

### Basic Usage

```bash
cd ansible

# Start both stacks
ansible-playbook playbooks/start.yml

# Stop both stacks
ansible-playbook playbooks/stop.yml

# Restart both stacks
ansible-playbook playbooks/restart.yml

# Check status
ansible-playbook playbooks/status.yml
```

## 📚 Available Playbooks

### Main Playbook

**`playbooks/site.yml`** - The primary playbook with all functionality:

```bash
# Validate environment and configuration
ansible-playbook playbooks/site.yml --tags validate

# Start operations
ansible-playbook playbooks/site.yml --tags start          # Both stacks
ansible-playbook playbooks/site.yml --tags start-prod     # Production only
ansible-playbook playbooks/site.yml --tags start-beta     # Beta only

# Stop operations
ansible-playbook playbooks/site.yml --tags stop           # Both stacks
ansible-playbook playbooks/site.yml --tags stop-prod      # Production only
ansible-playbook playbooks/site.yml --tags stop-beta      # Beta only

# Restart operations
ansible-playbook playbooks/site.yml --tags restart        # Both stacks
ansible-playbook playbooks/site.yml --tags restart-prod   # Production only
ansible-playbook playbooks/site.yml --tags restart-beta   # Beta only

# Status and monitoring
ansible-playbook playbooks/site.yml --tags status         # Show status
ansible-playbook playbooks/site.yml --tags logs           # Show recent logs
```

### Convenience Playbooks

For shorter commands:

```bash
# Start both stacks
ansible-playbook playbooks/start.yml

# Stop both stacks
ansible-playbook playbooks/stop.yml

# Restart both stacks
ansible-playbook playbooks/restart.yml

# Check status
ansible-playbook playbooks/status.yml
```

## 🏗️ Directory Structure

```
ansible/
├── ansible.cfg                 # Ansible configuration
├── requirements.yml            # Required Ansible collections
├── inventory/
│   └── hosts.yml              # Inventory (localhost by default)
├── playbooks/
│   ├── site.yml               # Main playbook (all operations)
│   ├── start.yml              # Quick start playbook
│   ├── stop.yml               # Quick stop playbook
│   ├── restart.yml            # Quick restart playbook
│   └── status.yml             # Quick status playbook
└── roles/
    ├── setup/                 # Prerequisites verification
    │   └── tasks/main.yml
    ├── environment/           # Environment configuration
    │   └── tasks/main.yml
    └── stack/                 # Stack operations
        └── tasks/main.yml
```

## 🔧 Roles

### Setup Role

Verifies prerequisites:
- Docker installation
- Docker Compose availability
- User docker group membership
- Required directories

Run with: `ansible-playbook playbooks/site.yml --tags setup`

### Environment Role

Manages configuration:
- Checks for `.env` files
- Validates Tailscale auth keys
- Validates docker-compose.yaml syntax

Run with: `ansible-playbook playbooks/site.yml --tags validate`

### Stack Role

Manages stack operations:
- Start/stop/restart stacks
- Configure Tailscale Serve
- Monitor status
- View logs

## 🎯 Common Workflows

### Daily Operations

```bash
cd ansible

# Morning: Start everything
ansible-playbook playbooks/start.yml

# During work: Restart just beta for testing
ansible-playbook playbooks/site.yml --tags restart-beta

# Evening: Stop everything
ansible-playbook playbooks/stop.yml
```

### Deployment to New Server

```bash
cd ansible

# 1. Verify prerequisites
ansible-playbook playbooks/site.yml --tags setup

# 2. Validate configuration
ansible-playbook playbooks/site.yml --tags validate

# 3. Start production stack
ansible-playbook playbooks/site.yml --tags start-prod

# 4. Check status
ansible-playbook playbooks/status.yml
```

### Troubleshooting

```bash
# Check what's running
ansible-playbook playbooks/status.yml

# Restart a specific stack
ansible-playbook playbooks/site.yml --tags restart-prod

# View recent logs
ansible-playbook playbooks/site.yml --tags logs

# Full reset (stop and start)
ansible-playbook playbooks/stop.yml
ansible-playbook playbooks/start.yml
```

## 🆚 Ansible vs Bash Script

Both tools coexist and can be used interchangeably:

### Use Ansible When:
- ✅ You want idempotent operations
- ✅ You need to manage multiple servers
- ✅ You prefer infrastructure-as-code
- ✅ You want detailed structured output
- ✅ You're integrating with CI/CD pipelines

### Use Bash Script When:
- ✅ You want quick, familiar commands
- ✅ You need interactive operations
- ✅ You prefer simpler syntax
- ✅ You're doing ad-hoc debugging
- ✅ You want emoji output 🎉

**Example Comparison:**

```bash
# Ansible approach
ansible-playbook playbooks/start.yml

# Bash script approach
./manage.sh start

# Both do the same thing!
```

## 🔐 Environment Variables

The playbooks use the same environment files as the bash scripts:
- `production/.env` - Production Tailscale auth key
- `beta/.env` - Beta Tailscale auth key

Ensure these files exist and contain valid `TS_AUTHKEY` values before running playbooks.

## 📊 Inventory Configuration

The default inventory (`inventory/hosts.yml`) uses localhost. To manage remote servers:

```yaml
# inventory/hosts.yml
all:
  hosts:
    production_server:
      ansible_host: 192.168.1.100
      ansible_user: deploy
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
  
  vars:
    project_root: /home/deploy/jarvis
    # ... other vars
```

Then run playbooks against remote hosts:

```bash
ansible-playbook playbooks/start.yml -l production_server
```

## 🐛 Debugging

Enable verbose output:

```bash
# Verbose
ansible-playbook playbooks/start.yml -v

# More verbose
ansible-playbook playbooks/start.yml -vv

# Very verbose (connection debugging)
ansible-playbook playbooks/start.yml -vvv
```

Check syntax without running:

```bash
ansible-playbook playbooks/site.yml --syntax-check
```

Dry run (check mode):

```bash
ansible-playbook playbooks/site.yml --check --tags start
```

## 🔄 Integration with CI/CD

Example GitHub Actions workflow:

```yaml
name: Deploy Jarvis
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Ansible
        run: |
          pip3 install ansible
          ansible-galaxy install -r ansible/requirements.yml
      
      - name: Deploy to production
        run: |
          cd ansible
          ansible-playbook playbooks/site.yml --tags start-prod
```

## 📝 Best Practices

1. **Always validate first**: Run `--tags validate` before making changes
2. **Use tags**: Target specific operations with `--tags`
3. **Check status**: Use `status.yml` to verify state
4. **Version control**: Keep playbooks in git
5. **Test in beta**: Use `--tags start-beta` for testing changes
6. **Document changes**: Update this README when adding playbooks

## 🆘 Troubleshooting

### "Module community.docker not found"

```bash
# Install required collections
ansible-galaxy install -r requirements.yml
```

### "Docker daemon not accessible"

```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### "Cannot connect to localhost"

```bash
# Check inventory
ansible-inventory --list -i inventory/hosts.yml

# Verify connection
ansible localhost -m ping -i inventory/hosts.yml
```

### "Playbook runs but containers don't start"

```bash
# Check Docker Compose directly
cd ..
docker compose --profile all ps

# Check logs
docker compose --profile all logs
```

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Compose Module](https://docs.ansible.com/ansible/latest/collections/community/docker/docker_compose_v2_module.html)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
- [Project README](../README.md)
- [Stack Management Guide](../STACK_MANAGEMENT.md)

## 🎓 Learning Path

1. **Start Simple**: Use convenience playbooks (`start.yml`, `stop.yml`)
2. **Learn Tags**: Use `site.yml` with `--tags` for specific operations
3. **Explore Roles**: Read role tasks to understand operations
4. **Customize**: Modify inventory for remote servers
5. **Extend**: Add custom playbooks for your workflows

## 📞 Support

For issues:
1. Check [`../TROUBLESHOOTING.md`](../TROUBLESHOOTING.md)
2. Run with `-vvv` for detailed output
3. Compare with bash script behavior (`./manage.sh`)
4. Check Docker logs: `docker compose logs`

---

**Remember**: Ansible and the bash script (`manage.sh`) are complementary tools. Choose the one that best fits your current workflow! 🚀

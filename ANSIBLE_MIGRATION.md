# Ansible Migration Guide

This guide explains the migration from bash script management to Ansible, and how both can coexist.

## 🎯 Overview

Jarvis now supports **two management approaches** that work side-by-side:

1. **Bash Script** (`manage.sh`) - Quick, interactive, imperative
2. **Ansible** (`ansible/`) - Declarative, idempotent, infrastructure-as-code

**Both are fully functional and can be used interchangeably.** Choose based on your needs!

## 🆚 Comparison

| Feature | Bash Script | Ansible |
|---------|------------|---------|
| **Learning Curve** | Very easy | Moderate |
| **Setup Time** | Zero (ready to use) | ~5 minutes (install collections) |
| **Command Length** | Short (`./manage.sh start`) | Short with Makefile (`make start`) |
| **Idempotency** | Partial | Full |
| **Multi-Server** | Manual per server | Built-in support |
| **CI/CD Integration** | Possible but limited | Native support |
| **Error Handling** | Basic | Advanced |
| **Logging** | Simple output | Structured YAML output |
| **Rollback** | Manual | Can be scripted |
| **Configuration Management** | Not included | Built-in validation |
| **Best For** | Daily operations | Production deployments |

## 🔄 Command Equivalence

### Start Operations

```bash
# Bash
./manage.sh start
./manage.sh start-prod
./manage.sh start-beta

# Ansible
cd ansible && make start
cd ansible && make start-prod
cd ansible && make start-beta

# Ansible (direct)
cd ansible && ansible-playbook playbooks/start.yml
cd ansible && ansible-playbook playbooks/site.yml --tags start-prod
cd ansible && ansible-playbook playbooks/site.yml --tags start-beta
```

### Stop Operations

```bash
# Bash
./manage.sh stop
./manage.sh stop-prod
./manage.sh stop-beta

# Ansible
cd ansible && make stop
cd ansible && make stop-prod
cd ansible && make stop-beta
```

### Restart Operations

```bash
# Bash
./manage.sh restart
./manage.sh restart-prod
./manage.sh restart-beta

# Ansible
cd ansible && make restart
cd ansible && make restart-prod
cd ansible && make restart-beta
```

### Status and Logs

```bash
# Bash
./manage.sh status
./manage.sh logs
./manage.sh logs-prod
./manage.sh logs-beta

# Ansible
cd ansible && make status
cd ansible && make logs
# Note: Ansible logs show last 100 lines, bash script can follow in real-time
```

### Configuration Validation

```bash
# Bash
./manage.sh validate

# Ansible
cd ansible && make validate
```

## 📋 Migration Scenarios

### Scenario 1: Trying Ansible Alongside Bash

**No migration needed!** Just start using Ansible:

```bash
# Continue using bash as normal
./manage.sh start

# Also try Ansible
cd ansible
./quickstart.sh    # One-time setup
make status        # Works alongside bash

# Use whichever you prefer
```

### Scenario 2: Gradual Migration

**Week 1-2: Learn Ansible**
```bash
# Keep using bash for critical operations
./manage.sh start-prod

# Practice with beta using Ansible
cd ansible
make start-beta
make restart-beta
make stop-beta
```

**Week 3-4: Mix Both**
```bash
# Use bash for quick checks
./manage.sh status

# Use Ansible for deployments
cd ansible
make restart-prod
```

**Week 5+: Primarily Ansible**
```bash
# Ansible becomes primary
cd ansible
make start
make status

# Keep bash as backup
./manage.sh help  # Still works!
```

### Scenario 3: Full Ansible Adoption

**For teams wanting pure infrastructure-as-code:**

1. **Initial Setup**
   ```bash
   cd ansible
   ./quickstart.sh
   ```

2. **Create wrapper script** (optional, at project root):
   ```bash
   # Create: jarvis.sh
   #!/bin/bash
   cd ansible && make "$@"
   
   # Usage:
   ./jarvis.sh start
   ./jarvis.sh status
   ```

3. **Update documentation** for your team

4. **Keep manage.sh** as fallback for emergencies

## 🎓 When to Use Which

### Use Bash Script When:
- ✅ Quick daily operations
- ✅ Interactive debugging
- ✅ Learning the system
- ✅ Single server management
- ✅ Following logs in real-time
- ✅ You want emoji output 😊

### Use Ansible When:
- ✅ Production deployments
- ✅ CI/CD pipelines
- ✅ Multi-server management
- ✅ Configuration validation
- ✅ Idempotent operations needed
- ✅ Infrastructure as code approach
- ✅ Team collaboration on runbooks

## 🚀 Quick Start Paths

### Path A: Just Want to Get Started (Bash)

```bash
# 1. Setup environment
cp production/.env.example production/.env
cp beta/.env.example beta/.env
# Edit .env files with your Tailscale keys

# 2. Start using immediately
./manage.sh start
./manage.sh status
```

**Time: 2 minutes**

### Path B: Want Infrastructure as Code (Ansible)

```bash
# 1. Setup environment (same as above)
cp production/.env.example production/.env
cp beta/.env.example beta/.env
# Edit .env files with your Tailscale keys

# 2. Setup Ansible
cd ansible
./quickstart.sh

# 3. Start using
make start
make status
```

**Time: 5 minutes**

### Path C: Want Both Options

```bash
# 1. Setup environment
cp production/.env.example production/.env
cp beta/.env.example beta/.env
# Edit .env files with your Tailscale keys

# 2. Setup Ansible
cd ansible
./quickstart.sh
cd ..

# 3. Use either approach
./manage.sh start        # Bash way
cd ansible && make start # Ansible way
```

**Time: 5 minutes**

## 🔧 Advanced Ansible Features

### Multi-Server Management

Edit `ansible/inventory/hosts.yml`:

```yaml
all:
  hosts:
    prod_server_1:
      ansible_host: 192.168.1.100
      ansible_user: deploy
    prod_server_2:
      ansible_host: 192.168.1.101
      ansible_user: deploy
  vars:
    project_root: /opt/jarvis
```

Then deploy to all:
```bash
cd ansible
ansible-playbook playbooks/start.yml
```

### CI/CD Integration

Example GitHub Actions:

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
      
      - name: Setup Ansible
        run: |
          pip3 install ansible
          cd ansible
          ansible-galaxy install -r requirements.yml
      
      - name: Deploy
        run: |
          cd ansible
          ansible-playbook playbooks/site.yml --tags start-prod
```

### Custom Playbooks

Create your own workflows:

```yaml
# ansible/playbooks/custom-deploy.yml
---
- name: Custom deployment workflow
  hosts: localhost
  tasks:
    - name: Stop old version
      import_role:
        name: stack
      tags: [stop-prod]
    
    - name: Pull latest changes
      git:
        repo: https://github.com/arrfour/jarvis.git
        dest: "{{ project_root }}"
        version: main
    
    - name: Start new version
      import_role:
        name: stack
      tags: [start-prod]
```

## 📊 Feature Comparison Matrix

| Feature | Bash | Ansible | Notes |
|---------|------|---------|-------|
| Start both stacks | ✅ | ✅ | Identical functionality |
| Start single stack | ✅ | ✅ | Identical functionality |
| Stop operations | ✅ | ✅ | Identical functionality |
| Restart operations | ✅ | ✅ | Identical functionality |
| Status checking | ✅ | ✅ | Identical functionality |
| Log viewing | ✅ | ⚠️ | Bash better for real-time following |
| Configuration validation | ✅ | ✅ | Ansible more comprehensive |
| Tailscale Serve config | ✅ | ✅ | Both auto-configure |
| Interactive prompts | ✅ | ❌ | Bash for destructive operations |
| Idempotency | ⚠️ | ✅ | Ansible guarantees same result |
| Multi-server | ❌ | ✅ | Ansible native support |
| Dry run | ❌ | ✅ | Ansible --check mode |
| Rollback support | ❌ | ✅ | Ansible can script rollbacks |
| Error recovery | Basic | Advanced | Ansible detailed error handling |
| Version control friendly | ✅ | ✅ | Both commit-friendly |
| Documentation as code | ⚠️ | ✅ | Ansible self-documenting |

## 🛠️ Troubleshooting Both Approaches

### Both Tools Show Different States

```bash
# Reset to known state
./manage.sh stop
cd ansible && make status

# If discrepancy persists
docker compose --profile all ps  # Check actual state
```

### Ansible Command Works, Bash Doesn't

```bash
# Check bash script permissions
ls -la manage.sh
chmod +x manage.sh

# Check path
./manage.sh help
```

### Bash Command Works, Ansible Doesn't

```bash
# Verify Ansible setup
cd ansible
ansible-playbook playbooks/site.yml --syntax-check

# Check collections
ansible-galaxy collection list | grep docker

# Reinstall if needed
./quickstart.sh
```

## 📚 Additional Resources

### Bash Script Documentation
- [Main README](../README.md)
- [STACK_MANAGEMENT.md](../STACK_MANAGEMENT.md)
- [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)

### Ansible Documentation
- [ansible/README.md](README.md)
- [Ansible Official Docs](https://docs.ansible.com/)
- [Docker Compose Module](https://docs.ansible.com/ansible/latest/collections/community/docker/docker_compose_v2_module.html)

## 🎯 Decision Tree

```
Need to manage Jarvis?
├─ Single server only?
│  ├─ Quick daily operations? → Use Bash Script
│  └─ Production deployment? → Use Either (preference)
│
├─ Multiple servers?
│  └─ Use Ansible (multi-host inventory)
│
├─ CI/CD integration?
│  └─ Use Ansible (better automation)
│
├─ New to the project?
│  └─ Start with Bash Script (simpler)
│
└─ Want infrastructure as code?
   └─ Use Ansible (declarative approach)
```

## 💡 Best Practices

1. **Keep Both Tools Working**
   - Don't remove manage.sh even if using Ansible
   - Both provide value in different scenarios

2. **Use Ansible for Automation**
   - CI/CD pipelines
   - Scheduled deployments
   - Multi-server operations

3. **Use Bash for Interaction**
   - Quick checks during development
   - Real-time log following
   - Interactive debugging

4. **Document Your Choice**
   - Tell your team which to use
   - Update documentation accordingly
   - Provide examples for both

5. **Version Control Everything**
   - Commit playbook changes
   - Version inventory files
   - Track configuration updates

## 🎉 Conclusion

You now have **two powerful tools** for managing Jarvis:

- **Bash Script** - Fast, familiar, friendly
- **Ansible** - Professional, powerful, scalable

**Use whichever fits your workflow!** Both are maintained, documented, and fully supported.

Happy deploying! 🚀

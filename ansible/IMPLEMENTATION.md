# Ansible Implementation Notes

## Architecture

This Ansible implementation provides declarative infrastructure-as-code management for the Jarvis stack while maintaining full compatibility with the existing bash scripts.

### Design Principles

1. **Non-Breaking**: Bash scripts continue to work unchanged
2. **Idempotent**: Safe to run repeatedly with accurate change tracking
3. **Declarative**: Describe desired state, not steps
4. **Maintainable**: Centralized configuration via role defaults
5. **Extensible**: Ready for multi-server and CI/CD scenarios

### Directory Structure

```
ansible/
├── ansible.cfg                 # Ansible configuration
├── requirements.yml            # Galaxy collections needed
├── Makefile                    # Convenient command shortcuts
├── quickstart.sh              # First-time setup helper
├── README.md                   # User documentation
│
├── inventory/
│   └── hosts.yml              # Inventory with path variables
│
├── playbooks/
│   ├── site.yml               # Main orchestration playbook
│   ├── start.yml              # Quick start playbook
│   ├── stop.yml               # Quick stop playbook
│   ├── restart.yml            # Quick restart playbook
│   └── status.yml             # Quick status check
│
└── roles/
    ├── setup/                 # Prerequisites verification
    │   └── tasks/main.yml
    ├── environment/           # Configuration validation
    │   └── tasks/main.yml
    └── stack/                 # Stack operations
        ├── defaults/main.yml  # Configuration variables
        └── tasks/main.yml     # Operation tasks
```

## Key Components

### 1. Inventory (inventory/hosts.yml)

- Defines localhost as target
- Sets path variables using `playbook_dir | dirname | dirname` to find project root
- Configures profiles for production and beta stacks

### 2. Main Playbook (playbooks/site.yml)

- Orchestrates all three roles
- Uses tags to control which operations run
- Supports both targeted and full runs

### 3. Roles

#### Setup Role
- Verifies Docker installation
- Checks Docker Compose availability
- Validates user permissions
- Confirms directory structure

#### Environment Role
- Checks for .env files
- Validates Tailscale auth keys presence
- Validates Docker Compose configuration syntax
- Provides helpful warning messages

#### Stack Role
- Manages Docker Compose operations (start/stop/restart)
- Configures Tailscale Serve automatically
- Supports both stacks together or individually
- Uses variables from defaults for flexibility

### 4. Role Defaults (roles/stack/defaults/main.yml)

Centralizes configuration:
- Service names (prod_services, beta_services)
- Container names (tailscale_prod_container, tailscale_beta_container)
- Port bindings (tailscale_prod_port, tailscale_beta_port)

Benefits:
- Single source of truth
- Easy to customize
- Reduced duplication
- Improved maintainability

## Implementation Decisions

### Path Resolution

Used `playbook_dir | dirname | dirname` instead of simpler approaches because:
- Playbooks are in `ansible/playbooks/`
- Need to reach project root (two levels up)
- Maintains proper relative paths
- Works regardless of execution location

### Changed_when Conditions

Use explicit return code checking (`rc == 0`) or output checking for accuracy:
- More reliable than checking stderr content
- Proper idempotency
- Clear success/failure detection

### Service Name Variables

Use Jinja2 filters to join service lists:
```yaml
command: docker compose restart {{ prod_services | join(' ') }}
```

Benefits:
- Maintains list in defaults
- Easy to add/remove services
- Consistent across operations

### Tailscale Configuration

Separate tasks for production and beta with conditional execution:
- Only runs when stacks are started/restarted
- Uses variables for container names and ports
- Allows failures (Tailscale may already be configured)

## Usage Patterns

### Daily Operations
```bash
cd ansible
make start          # Quick start
make status         # Check status
```

### Targeted Operations
```bash
cd ansible
make restart-beta   # Just beta
make start-prod     # Just production
```

### Advanced Usage
```bash
cd ansible
ansible-playbook playbooks/site.yml --tags validate
ansible-playbook playbooks/site.yml --tags setup
ansible-playbook playbooks/site.yml --tags start-prod,start-beta
```

### CI/CD Integration
```yaml
- name: Deploy
  run: |
    cd ansible
    ansible-galaxy install -r requirements.yml
    ansible-playbook playbooks/start.yml
```

## Extensibility

### Multi-Server Support

Edit inventory to add remote hosts:
```yaml
all:
  hosts:
    server1:
      ansible_host: 192.168.1.100
    server2:
      ansible_host: 192.168.1.101
```

### Custom Operations

Create new playbooks:
```yaml
# playbooks/backup.yml
- import_playbook: site.yml
  tags: [stop]

- name: Backup data
  hosts: localhost
  tasks:
    - name: Backup volumes
      # ... backup tasks
```

### Configuration Override

Override defaults at inventory level:
```yaml
all:
  vars:
    prod_services:
      - open-webui2
      - tailscale-sidecar
      - nginx-prod
      - custom-service
```

## Comparison with Bash Script

| Aspect | Bash Script | Ansible |
|--------|-------------|---------|
| Complexity | Simple | Moderate |
| Idempotency | Partial | Full |
| Multi-server | Manual | Built-in |
| Change tracking | Limited | Comprehensive |
| Documentation | Comments | Self-documenting |
| Error handling | Basic | Advanced |
| CI/CD ready | Limited | Native |

## Best Practices

1. **Always validate first**: Run `make validate` before changes
2. **Use tags**: Target specific operations with `--tags`
3. **Check syntax**: Use `--syntax-check` during development
4. **Test in beta**: Use beta stack for testing new operations
5. **Document changes**: Update README when adding functionality
6. **Version control**: Commit playbook and inventory changes
7. **Use variables**: Put configuration in defaults, not tasks

## Troubleshooting

### Playbook Hangs
- Check if Docker daemon is running
- Verify .env files exist
- Use `-vvv` for verbose output

### Path Issues
- Verify inventory path variables
- Check `playbook_dir` resolution
- Test with `ansible-inventory --list`

### Change Detection
- Review `changed_when` conditions
- Check command output in verbose mode
- Verify return codes

## Future Enhancements

Potential additions:
1. Backup/restore playbooks
2. Health check tasks
3. Monitoring integration
4. Automated testing playbooks
5. Deployment rollback support
6. Multi-environment management
7. Secret management with Ansible Vault

## Conclusion

This implementation provides a professional, production-ready Ansible solution that:
- Works alongside existing tools
- Follows Ansible best practices
- Is well-documented and maintainable
- Can scale from single-server to enterprise deployments
- Provides a foundation for advanced automation

The modular design and extensive documentation make it easy for users to adopt gradually or fully, based on their needs.

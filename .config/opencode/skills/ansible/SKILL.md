---
name: Ansible
description: Ansible playbook and role best practices: idempotency, validation, and temp-file handling. Load when writing or reviewing Ansible.
---

## Conventions

- Use `ansible.builtin.assert` for validation checks instead of `fail` with `when` conditions.
- Prefer simplicity by avoiding complex backup/rollback systems, unless data cannot be recreated.
- Make tasks idempotent by checking state before running commands (e.g., check if a file exists before running a command that creates it).
- Validate inputs early (preflight checks) but let Ansible modules fail naturally rather than duplicating their validation logic.
- For non-critical data backups, or when creating/writing temporary files and directories, use OS temp directories and let the OS clean up automatically.
- Roles describe the end state a host should reach. Do not put checks, gates, or run preconditions inside a role (for example scheduled-reboot or reachability guards); express  them as shared task files, such as `playbooks/tasks/*.yaml`, that the playbook includes before its roles.

## Verify

- `ansible-lint` is the static-analysis gate for Ansible projects.

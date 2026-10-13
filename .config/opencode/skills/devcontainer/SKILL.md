---
name: Dev Container
description: Development container conventions: users, UID/GID mapping, remoteUser, and spec-compliant security relaxations. Load when authoring devcontainer.json or Containerfiles.
---

## Conventions

- Use the `vscode` user (Microsoft convention) for interactive development, not `linuxbrew` or custom names.
- Match host UID/GID at build time via `build.args` when using tools that do not implement `updateRemoteUserUID`.
- Use `remoteUser` for dev tools and lifecycle hooks; do not set `containerUser` to a non-root user.
- Use spec-compliant properties (`capAdd`, `securityOpt`) instead of Docker-specific `runArgs`.
- Security relaxations (like `capAdd` and `securityOpt`) are acceptable for dev containers but must be documented with inline comments explaining the accepted risk.
- Keep the container's default user as `root` for orchestrator setup, then drop to `remoteUser` for dev work.

## Verify

- `hadolint` is the lint gate for Containerfiles.

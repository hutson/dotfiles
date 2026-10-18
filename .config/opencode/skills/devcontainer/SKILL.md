---
name: Dev Container
description: Development container conventions: users, UID/GID mapping, remoteUser, and the deny-by-default security posture. Load when authoring devcontainer.json or Containerfiles.
---

## Conventions

- Use the `vscode` user (Microsoft convention) for interactive development, not `linuxbrew` or custom names.
- Match host UID/GID at build time via `build.args` when using tools that do not implement `updateRemoteUserUID`.
- Use `remoteUser` for dev tools and lifecycle hooks; do not set `containerUser` to a non-root user.
- Never add `capAdd`, `securityOpt`, or privileged `runArgs` unless the project has a hard requirement for the capability (ptrace-based debugging, for example) and the human has explicitly confirmed the relaxation with the `question` tool. Without both, the container keeps the platform's default security profile.
- Declare a confirmed relaxation with the spec-compliant property (`capAdd`, `securityOpt`) rather than Docker-specific `runArgs`.
- Keep `devcontainer.json` free of comments and documentation: it carries configuration only. The human's confirmation is the record of accepted risk, and any rationale they want persisted belongs in the Containerfile or the readme at their direction.
- Keep the container's default user as `root` for orchestrator setup, then drop to `remoteUser` for dev work.

## Verify

- `hadolint` is the lint gate for Containerfiles.

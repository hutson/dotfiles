---
name: Security Tooling Architecture
description: Offline, deterministic security scanning and enforcement: single-binary language tools with embedded rules, the secret-scanning gate, install surfaces kept in sync, and the postponed SCA seam. Load when adding security gates to a project, scaffolding a new project, or choosing a security tool.
---

# Security Tooling Architecture

Security scanning and enforcement lives in each project's `.tools/test.sh` entry point, composed by the `scaffold` skill. This skill decides which tools qualify and how they are wired so every gate is deterministic and runs with no network at scan time.

## Conventions

- Scans run entirely offline at scan time: no telemetry, no rule or database downloads, no registry lookups. A gate must be reproducible from the repository plus the pinned tool alone.
- Prefer a language-specific scanner distributed as a single self-contained binary with its rules embedded. This replaces rule-set maintenance with tool upgrades: refreshing coverage means bumping a pinned version, not vendoring, syncing, or license-reviewing YAML rules. (Opengrep/Semgrep were rejected for exactly this reason: they ship no rules, and community rule sets are either too thin to matter or carry redistribution limits. Trivy was rejected: its Ansible coverage is experimental and limited to AWS S3 module checks, which is nothing for the configuration-management repos it would run against.)
- Every security gate fails the entry point on any finding. No warnings-only gates: a finding is fixed, or allowlisted in the tool's own config file with the reason recorded there.
- Tool settings live in the project's config files rather than command-line flags, so the Dev Container, host, and CI runs share one configuration.
- Per-language static analysis belongs to the language's own stack skill; this skill owns only the cross-cutting secret-scanning gate and the composition rules below. The existing stack gates are already the security scanners for their stacks: `shellcheck` (bash), `hadolint` (devcontainer), `ansible-lint` with `profile: production` and `offline: true` (ansible), `golangci-lint` with `default: all`, which includes gosec (go), and `biome` (typescript; hygiene only, see "Known gaps").
- The security block is composed after the hygiene stacks (`devcontainer`, `bash`) and before the language stacks, with secret scanning leading it: a leaked credential is the highest-severity finding and the cheapest to detect.
- Every tool a composed gate invokes is installed on each surface that runs the gate, so a developer, the Dev Container, and CI see the same version: the project's `.devcontainer/Containerfile` (pinned release, checksum verified with `sha256sum --check --strict`, matching the hadolint install pattern), the dotfiles repository's `Brewfile` for host use, and any CI workflow (an install step before the test step).

## Verify

- `gitleaks dir . --no-banner` is the secret-scanning gate for every project. It is a single Go binary (Apache-2.0) whose rule set is embedded, performs no network calls, and exits non-zero on any finding; a repository scan takes about a second.
- The config search order is `--config`, `GITLEAKS_CONFIG`, then `.gitleaks.toml` beside the scan target, falling back to the embedded default rules. Add a project-root `.gitleaks.toml` only when the gate actually misfires (generated or documentation files), and start it with `[extend]` and `useDefault = true`: a plain custom `[rules]` list silently replaces the entire embedded set instead of adding to it.
- `gitleaks git` scans commit history. It is a one-time intake command when adopting the gate on a repository with history, never a `test.sh` gate: history findings cannot be fixed by the change under validation.

## Software composition analysis (postponed)

SCA matches third-party dependencies against a vulnerability database, so unlike the scans above it cannot travel as embedded rules in a pinned binary; the advisory dataset is rolling. Vendoring it in git is ruled out by size (measured 2026-10, compressed OSV per-ecosystem dumps: Go ~12 MB, PyPI ~36 MB, npm ~218 MB). The design seam is recorded so adoption later is mechanical:

- Scanner: `osv-scanner` (single Go binary, Apache-2.0), scanning lockfiles against local OSV databases with `--offline`.
- Database location: `OSV_SCANNER_LOCAL_DB_CACHE_DIRECTORY=$XDG_CACHE_HOME/osv-scanner`, primed per ecosystem, never committed.
- Refresh: an explicit network-enabled `.tools/refresh-security-data.sh` maintenance step (the same pattern as the Dev Container's primed npm cache), never part of `test.sh`.
- Gate behavior: fails closed when the cache is absent, pointing at the refresh script, matching the `npm ci --offline` contract; a staleness warning nudges periodic refreshes.

## Known gaps

- JavaScript and TypeScript have no single-binary, embedded-rules security linter today (oxlint's eslint-plugin-security support is alpha; Semgrep-class engines were rejected above). Biome covers hygiene; accept the gap until a real JS application surface justifies a dedicated tool.
- Lua's `luacheck` is correctness-focused; the Luanti risk surface (`minetest.deserialize`, `loadstring`, `os.execute`) would need hand-written checks, which inventing custom lint tooling (forbidden by the project rules) is not justified for self-authored mods on a trusted server.
- Terraform, Kubernetes manifests, and CI pipeline configs are not security-scanned; none exist in the current projects. Revisit only if such code appears.

---
name: Go
description: Go language best practices, security pitfalls, testing patterns, and verification. Load when working in a Go project.
---

## Conventions

- When creating a new Go project, `go.mod` should use the oldest supported version of Go, 1.26.0, for the `go` directive, separate from the value of toolchain, to ensure our Go module is compatible with all supported versions of Go.
- Run tests with: `go test -failfast -race -cpu=1,24 -cover -coverprofile=coverage.out`
- Use `-run` during development for targeted feedback from tests related to work in progress, but exclude `-run` for final validation.
- Name test files `<package>_test.go`; the `guardrails` plugin treats them as protected test files (never deleted or blanked).
- Prefer the standard library over third-party dependencies; when the standard library does not cover the need, choose a well-maintained dependency and pin it (`go.sum`).

## Verify

- `golangci-lint ./...` is the static-analysis gate for Go code; configure it for maximum rigor in the project's config file.
- `gofmt -l .` is the format gate; code must already be formatted.
- `go test -failfast -race -cpu=1,24 -cover -coverprofile=coverage.out` is the dynamic analysis gate.

When creating a new Go project, set the project up with `golangci-lint` with the following configuration in `.golangci.yaml`

```yaml
version: "2"

linters:
  # Run every available linter at its default settings; only the four listed
  # below are turned off, each with a justification.
  default: all
  disable:
    # Deprecated since v2.2.0: superseded by the maintained rewrites, which
    # `default: all` also enables. Keeping both double-reports the same issues.
    - wsl
    - exhaustruct
    - gomodguard
    # Redundant: an import must already be in go.mod to compile, so an
    # allow-list would just duplicate the module graph as bookkeeping.
    - depguard
  settings:
    godox:
      # TODO comments are a required project convention (see AGENTS.md testing
      # rules); FIXME and BUG markers remain flagged.
      keywords:
        - FIXME
        - BUG

issues:
  # Report every finding: the defaults (50 per linter, 3 per identical text)
  # silently truncate the list, which hides work still to be done.
  max-issues-per-linter: 0
  max-same-issues: 0

formatters:
  # All available formatters (v2 has no `default: all` for formatters; this is
  # the full list). `golangci-lint run` fails on any formatter deviation; run
  # `golangci-lint fmt` to apply them.
  enable:
    - gci
    - gofmt
    - gofumpt
    - goimports
    - golines
    - swaggo
```

---
name: Go
description: Go language best practices, security pitfalls, testing patterns, and verification. Load when working in a Go project.
---

## Conventions

- When creating a new Go project, `go.mod` should use the oldest supported version of Go, 1.26.0, for the `go` directive, separate from the value of toolchain, to ensure our Go module is compatible with all supported versions of Go.
- Build and test against every currently supported Go release by listing one toolchain per line in `.tools/toolchains.txt` (for example `go1.27.2` and `go1.26.9`); `GOTOOLCHAIN` iteration in the build and test scripts reads this file, so toolchain versions live in one place.
- Run tests with: `go test -failfast -race -cpu=1,24 -cover -coverpkg=./... -coverprofile=coverage.out`
- Use `-run` during development for targeted feedback from tests related to work in progress, but exclude `-run` for final validation.
- Name test files `<package>_test.go`; the `guardrails` plugin treats them as protected test files (never deleted or blanked).
- Prefer the standard library over third-party dependencies; when the standard library does not cover the need, choose a well-maintained dependency and pin it (`go.sum`).

## Verify

Run these gates in order; the `scaffold` skill assembles them into the project's single test entry point, one banner-delimited section per gate.

- `golangci-lint run ./...` is the static-analysis gate for Go code; configure it for maximum rigor in the project's config file. Its enabled formatters cover `gofmt`, so a formatting deviation fails this same gate rather than needing a separate `gofmt -l .` pass.
- `go mod tidy` followed by `git diff --exit-code go.mod go.sum`, then `go mod verify`, are the dependency-hygiene gates. Check tidiness against backup copies of `go.mod` and `go.sum` and restore the originals afterward; agents are denied Git write commands, so a `go mod tidy` that dirties the files cannot be reverted with `git checkout`.
- `go test -failfast -race -cpu=1,24 -cover -coverpkg=./... -coverprofile=coverage.out ./...` is the dynamic analysis gate, run once per toolchain in `.tools/toolchains.txt`. The `-cpu=1,24` sweep complements the race detector by exercising single-core scheduling and high concurrency. `-coverpkg=./...` instruments every package, not only packages that own test files, so untested code drags the total down instead of vanishing from the profile.
- `go tool cover -func=coverage.out | awk 'BEGIN { floor = 70 } /^total:/ { gsub(/%/, "", $3); seen = 1; ok = ($3 >= floor) } END { exit !(seen && ok) }'` is the coverage floor, run immediately after each toolchain's test gate: the gate fails when total statement coverage drops below 70%, or when the profile carries no total line at all, so an empty or unparsable run cannot pass vacuously. The floor lives in the entry point rather than in the loop's stop rules because a green run must already prove coverage: that keeps `quality-assurance` a deterministic runner instead of a number-judge, and a shortfall cycles the loop back through `developer` to broaden the suite. `go tool cover` (standard library) plus `awk` replaces a third-party threshold gate, so nothing extra needs pinning.

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

## Build

- Goals that ship standalone binaries compile through `.tools/build.sh`: every `GOOS`/`GOARCH` pair (linux, darwin, and windows, each on amd64 and arm64) for every toolchain in `.tools/toolchains.txt`, with `-ldflags="-s -w"` to strip the symbol and DWARF tables. The size reduction (typically 11MB to around 7MB) and the lost debug information are an acceptable trade because these projects ship structured logging for failure triage.
- Write artifacts to a per-run directory under `${TMPDIR:-/tmp}`, named after the project, rather than into the repository, so repeat runs stay non-destructive.
- Release container images build from the project's root `Containerfile` with `podman build --all-platforms`, passing OCI labels (created, name, revision, version) from `git rev-parse` and `git tag` output; reading that metadata is why the repository must be a Git repo before the container build runs.
- Do not compress binaries with `upx` by default: one-off testing cut a binary from 7MB to 3MB but raised startup from around 0.005s to 0.060s, a tenfold runtime cost for a bandwidth saving that rarely matters for a CLI tool.

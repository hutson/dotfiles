---
name: TypeScript
description: TypeScript and JavaScript tool selection and verification: Biome for formatting and linting, config policy, and the check gate. Load when working in a TypeScript or JavaScript project.
---

## Conventions

- Biome is the single tool for formatting, linting, and organizing imports; do not run Prettier or ESLint alongside it.
- Run Biome with its defaults; create `biome.jsonc` only to record the deviations a project needs (excluding generated files, line width, and the like).
- Biome parses TypeScript but does not type-check; when type errors must gate a change, add `tsc --noEmit` (which requires a `tsconfig.json`) to the project's checks.
- Prefer the platform (the standard library and browser/Node APIs) over third-party dependencies; when a dependency is required, choose a well-maintained one and commit its lockfile.

## Verify

- `biome check --error-on-warnings .` is the combined format and lint gate; `biome check --write .` applies its fixes.
- Unit-testing strategy is deferred until a TypeScript project needs one. When it does, offer the human the standard runners (`node:test` from the Node platform, Vitest, or Jest) and record the choice; do not invent a custom runner, and do not let the scaffolding decide it.
- Whatever runner is chosen, a 70% coverage floor is part of its Verify gate, configured in the runner's own config file where it has one so the run fails below the threshold without an external check: Vitest `coverage.thresholds.statements: 70` (thresholds require a provider package such as `@vitest/coverage-v8`), Jest `coverageThreshold: { global: { statements: 70 } }`, and for `node:test` the flags `--experimental-test-coverage --test-coverage-lines=70` (line-based; the platform runner has no config file, and the flag exits 1 below the threshold).

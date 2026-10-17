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

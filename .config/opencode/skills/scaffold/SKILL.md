---
name: Scaffold
description: New project structure by stack and goal: the single test entry point, license, dotfiles, Dev Container, .tools/ scripts, and readme layout. Load when creating or bootstrapping a project, or when adding missing scaffolding to an existing one.
---

# Scaffold

Scaffold decides which files a project has and where they live, based on the languages in
use and what the project is for. Tool selection, testing strategy, and version numbers stay
in the stack skills (`go`, `bash`, `devcontainer`, `typescript`); this skill composes them
into a project layout and never duplicates their guidance.

## Contract

- `.tools/test.sh` is the project's single test entry point, and it is the project's `Verify` command.
- The readme's `## Development` section documents exactly that command, using this paragraph copied verbatim:

  > Validate changes with this project's single test entry point, `.tools/test.sh`. It runs the static analysis and dynamic tests a change needs, entirely offline and is non-destructive and repeatable. No other commands are necessary to validate a change.
- The readme's `## Design Decisions` section is created empty and stays empty until the human fills it. It records only high-level, subjective ground truths that direct future development (design, architecture, security posture). Implementation facts (a library in use, a tool name, a container detail) are not decisions: they live in the code and configuration that embody them. Agents never author entries; an entry appears only at the human's direction.
- Prose in every generated file is one line per paragraph, never hard wrapped (the `AGENTS.md` documentation rule). Files copied for exactness (`license.md`, `.golangci.yaml`) keep their source formatting.
- Scaffolding never relaxes security controls. A Dev Container gains `capAdd`, `securityOpt`, or privileged `runArgs` only when the project has a hard requirement for the capability and the human has explicitly confirmed it (the `devcontainer` skill owns the policy), and a generated `devcontainer.json` carries no comments.

- `license.md` is Apache-2.0 by default. Confirm the choice with the human before writing it; record any other choice as an assumption they can correct. Copy the license text from the dotfiles repository's `license.md` rather than writing it from memory (legal text must be exact, and the text never changes, so the copy is the canonical one).
- `.gitattributes` contains exactly `* text=auto eol=lf`.
- `.gitignore` covers the build outputs the project produces.
- Tests run entirely offline, are non-destructive and repeatable, and use full flag names (`--help`, not `-h`).
- If the folder is not a Git repository, ask the human to run `git init`. The `go mod tidy` cleanliness gate diffs against Git state, and `build.sh` reads Git metadata for container labels; agents are denied Git write commands.

## Process

1. Identify the stacks in use from the folder (`go.mod`, shell scripts, `package.json` or `*.ts`) and the project's goal from the request. Ask with the `question` tool when either is unclear, batching the stack, goal, and license confirmations into one call. When the project has a hard requirement for a security relaxation (ptrace-based debugging, for example), fold the relaxation confirmation into the same call; absent a confirmed requirement, the Dev Container keeps the platform's default security profile. Record inferred answers as correctable assumptions.
2. Load the matching stack skills: `bash` and `devcontainer` apply to every project, because every project ships `.tools/` shell scripts and a Dev Container; `security-tooling-architecture` applies to every project, because every project enforces secret scanning; add `go` and/or `typescript` for the languages present.
3. Create only the missing files from the table in "File sources", never overwrite an existing file. When a selected stack's gates are absent from an existing `.tools/test.sh`, add them (see "Composing .tools/test.sh").
4. Compose `.tools/test.sh` from the loaded stack skills' `Verify` gates.
5. Run `bash .tools/test.sh` and bring it green, fixing the scaffolding only; application code is out of scope for this skill.

## Structure by stacks and goals

Every project gets `readme.md`, `license.md`, `.gitattributes`, `.gitignore`, `.devcontainer/`, and `.tools/test.sh`.

On top of that, by goal (a project can hold more than one goal):

- CLI (or any goal distributing standalone binaries): add `.tools/build.sh` (cross-compilation per the `go` skill's Build section) and a release `Containerfile` at the project root. The readme gains `## Installation` and `## Usage` (with the CLI options) sections.
- Library: no `.tools/build.sh` and no release `Containerfile`. The readme gains `## Installation` (the import path) and a `## Usage` example calling the package programmatically.
- Service: add the release `Containerfile` (the image is the artifact) and a `## Deployment` section documenting configuration and environment; standalone-binary cross-compilation stays out unless the service also ships binaries.
- Scripts or config repo: add a `scripts/` directory for the project's own shell scripts and a `## Usage` section that inventories them.

The readme always closes with `## Design Decisions` and `## Development`. The Design
Decisions section is created empty and never filled by an agent: per the Contract, it is
the human's place to record the high-level ground truths that direct future development.
The Development section pairs the verbatim paragraph above with how to run the entry
point inside the Dev Container, including the fallback for hosts without the tooling
installed (`devsy ci . -- bash .tools/test.sh`), and ends there. Dev Container
provisioning, cache warming, and other environment implementation details are not readme
content; a requirement that should shape that implementation (offline operation, for
example) belongs in Design Decisions when the human records it there.

## File sources

| Project file | Source of truth |
| --- | --- |
| `.devcontainer/` | Copy from an existing checkout (semantic-tag is the living example), then rename the project, align the pins per "Versions" below, and adjust the installed tools to exactly the set the composed gates invoke: drop tools for stacks not in use, and add any missing ones (an older exemplar predating the composition model may lack, for example, `shfmt` and `shellcheck`). Treat the exemplar as structure, not security posture: strip any `capAdd`, `securityOpt`, or `runArgs` entries and every comment from the copied `devcontainer.json`, and add a relaxation back only when the project has a hard requirement and the human has confirmed it. The pattern itself is the `devcontainer` skill. |
| `.tools/build.sh` | Copy from an existing checkout of the same stack, adapt the binary name and targets; the build strategy is the `go` skill's Build section. |
| `.tools/toolchains.txt` | Populated per the `go` skill's toolchain policy. |
| `.golangci.yaml` | The config block in the `go` skill, copied byte-for-byte (maximal lint configuration is hard to validate by eye, so it is never rewritten from memory). |
| `biome.jsonc` | Only when the project deviates from Biome defaults; the `typescript` skill says when. |
| `.gitleaks.toml` | Only when the secret gate misfires on generated or documentation files; the `security-tooling-architecture` skill says when and how (`[extend]` with `useDefault`, never a bare `[rules]` list). |
| `license.md` | The dotfiles repository's `license.md`. |
| `readme.md` | The outline above, with the `## Development` paragraph copied verbatim and `## Design Decisions` left empty. |
| `.gitignore` | This project's build outputs. |
| `.tools/test.sh` | The frame below, filled by the loaded stack skills. |

**Versions.** Pinned versions (base images, tool releases, checksums) age the moment they
are copied. Treat exemplars as structure, not as version authority: at copy time, align
each pin with the guidance in its stack skill, or with the current release when no skill
names one.

## Composing .tools/test.sh

One banner-delimited section per gate, assembled from the `Verify` sections of the stack
skills loaded for this project. Order the sections: hygiene stacks (`devcontainer`, `bash`),
then the security block from `security-tooling-architecture` (secret scanning leads it), then
language stacks (`go`, `typescript`), and static-analysis gates before dynamic tests
within each stack. Security gates fail the entry point on any finding. The build hook runs last, only when the goal produces artifacts. Copy
this frame and fill it in (the frame omits the `#!/usr/bin/env bash` shebang on purpose: a
shebang anywhere in a file makes the `guardrails` plugin classify this skill file itself as
a shell script and demand the defensive `set` as its first line; when copying the frame to
`.tools/test.sh`, add the shebang as line 1):

```bash
set -o errexit -o nounset -o noglob -o pipefail
readonly _trace_start_time_us=${EPOCHREALTIME//./}
PS4='[DEBUGLEVEL:${SHLVL} SUBSHELL:${BASH_SUBSHELL} LINE:${LINENO} DIFF:$(us=$(( ${EPOCHREALTIME//./} - _trace_start_time_us )); ms=$(( us / 1000 )); printf "%d.%03d" $((ms / 1000)) $((ms % 1000)) )s SOURCE:${BASH_SOURCE}] '

project_name="$(basename "$(pwd)")"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==================== TESTING ${project_name^^} ===================="
echo "Starting comprehensive code quality checks..."
echo

# One section per gate, from each loaded stack skill's Verify section, in the
# order devcontainer, bash, security, then language stacks. Each section has
# this shape, and the command comes from the stack skill, never from memory:
#
#   echo "==================== <GATE NAME> ======================="
#   echo "Running <tool> to <purpose>..."
#   <the gate command from the stack skill's Verify section>
#   echo "'<tool>' passed"
#   echo

# Only when the goal produces artifacts, run the build after the tests pass:
#
# bash "${script_dir}/build.sh"
# echo

echo "==================== ALL CHECKS PASSED ==============="
echo "Code formatting, linting, and tests completed successfully"
```

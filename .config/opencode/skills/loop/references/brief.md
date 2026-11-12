# Brief composition checklist

Run this checklist on every worker brief, first dispatch and follow-up, before it ships. Every item exists because its absence cost a dispatch, a re-grade round, or an in-dispatch detour in a recorded loop; the list consolidates the recurring brief-composition friction in `~/.data/opencode/progress/loop-improvements.md`.

## Ground truth

- Paths appear exactly as they resolve from the repository root (for example `.config/opencode/agents/security.md`, never `agents/security.md`); a wrong path costs the worker a failed read.
- Every referenced prior list (gap lists, changed-file sets, prior verdicts, inventories) is restated verbatim in the brief. A fresh worker sees only the brief, never "the round-1 labels (a)-(e)" or "the seven changed files".
- A revision or follow-up brief pastes the prior text it revises, or continues the same worker by sessionID. Never instruct a fresh spawn to "keep the prior design as-is" without pasting that design.
- Edit payloads and pinned literals (identifiers, sentinel bytes, character counts) come from live command output or a live file read taken at brief-composition time and are quoted verbatim, never transcribed from prose renderings or projected captures; a stale literal forces the worker into identifier-tolerant workarounds or failed matches.
- Relayed facts from another session carry their source (worker, session, location) or are marked unverified. Verdict and evidence claims (especially "X passed end to end") travel with their raw evidence lines, never as paraphrase. A "still holds" claim inherited from a plan quotes the exact surviving text and the reading that verified it against the change.
- When stating surviving content, state the property to verify ("no surviving comment references the removed tooling") or quote the surviving content verbatim; never assemble an inventory of what survives from memory.
- Non-obvious mechanical states state their cause (for example: tracked files edited back to exact HEAD bytes by an edit that undoes an earlier change), so reviewers ground checks instead of inferring causes.
- Constraint deltas travel as explicit exclusion lists, never "everything else stands".
- Naming tokens (`<name>`, `<run>`, scratch paths) are defined against the human's stated convention, and the disposition of existing verbatim text (keep, replace, delete) is stated explicitly.

## Task shape

- The brief states the task's intended outcome and ends with the standing `FRICTION:` clause (see "Friction tracking and improvement").
- One-line content deltas are applied with the edit tool and verified by an immediate region diff, never sed-then-echo (a sed delta can echo correctly while later byte reads show corruption).
- Endorsement deltas appear as explicit old->new line contents; when a file-wide directive is replaced by per-line directives, every covered site is enumerated.
- Style and wrap policy is stated whenever comment placement is prescribed.
- Scratch instructions use absolute paths, forbid `cd` into external directories, and pick fresh filenames never recorded earlier in the loop (the manifest holds one immutable entry per path, so a reused name makes digest forensics ambiguous); give an example of the naming.

## Verdicts and routing

- Verdict keys match the phase: `CONFIRMED|REJECTED` for signal adjudication, `PASS|FAIL` for test changes (a bare PASS on an adjudication reads as endorsing the stale check).
- Grader findings route back verbatim, with each finding's per-check grep evidence for any missing-check or fails-today claim, so the fixer never re-derives the reviewer's reasoning.
- Closure judgments quote each open finding's original verdict beside its fix description.
- Mandated verdict lines are demanded as an explicit numbered output header, never left to be absorbed into a command log.

## Environment and venue

- Every deliverable matches the tools the dispatched session actually has: never demand `sha256sum`, `diff`, `cmp`, or `git` output from a session without those commands. State the read-tool comparison accepted as a substitute, and enumerate changed paths explicitly with each check's comparison basis.
- Gate and toolchain briefs state the authoritative venue up front (the Dev Container with its pinned toolchain) and name which named toolchain binaries exist on each side (host versus container); a host-tool-version failure on content the change did not touch is an artifact under the stated attribution rule, not a finding.
- Forbid `--write` formatters on file types the pinned toolchain's version ignores.
- When the venue runs through devsy, carry its workspace and wrapper-output facts from the `devsy` skill; any check that parses wrapper output is endorsed against captured transcript evidence, never a prose rendering.
- Instrumented timing re-runs are pre-approved or pre-declined in the brief; default to declining them.

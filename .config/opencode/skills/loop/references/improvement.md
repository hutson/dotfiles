# Loop friction taxonomy, improvement backlog, and exit retrospective

The durable half of the loop's self-improvement mechanism (the standing half, the effort log and the worker-brief clause, lives in `SKILL.md`). The mechanism costs almost nothing on a clean loop: standing structure in briefs, conditional content in returns, one durable store.

## Improvement buckets

Bucket each effort-log row into exactly one bucket, and root-cause each bucket to exactly one improvement target. The targets are the three places loop behavior is defined: instructions (`AGENTS.md`, `commands/`), skills (`skills/loop/**`), and agent definitions (`agents/*.md`).

- GOAL-GAP: the request left something open (a boundary, an interface surface, a scope) and a question round trip or a corrected assumption resolved it. Target: clarification instructions.
- SKILL-STRUCTURE: a question or step mandated by loop or AGENTS rules, not by user intent. Target: skills or instructions.
- ENV-GAP: a workflow or environment fact missing from the project's docs (a prerequisite the scaffold assumes, an entry point the loop could not establish). Target: skills or instructions.
- LATE-SURFACE: a decision that surfaced only after a worker ran but was knowable at phase 0 (a license default, a coverage-enforcement choice). Target: clarification instructions.
- WORKER-DRIFT: a worker produced work outside the recorded constraints (reintroducing excluded artifacts). Target: brief-composition rules (skills) or agent definitions.
- INSTRUCTION-CHURN: instructions changed mid-loop, so already-written state or briefs followed the old rules. Target: instructions (a propagation rule).
- SKILL-CONFLICT: two instruction sources conflicted and the human had to arbitrate. Target: whichever source is wrong.
- REWORK: a FAIL round or re-dispatch redoing work a first pass should have gotten right. REWORK is the cost, not the cause: when the underlying bucket is known, log that bucket instead, and use REWORK only when it is not.

## Improvement backlog

`~/.opencode/progress/loop-improvements.md`, append-only, one line per proposal:

    - <date> | <loop slug> | <bucket> | <target file> | <proposed change> | <expected saving> | <evidence: effort-log rows> | <mitigation in effect, or none> | <status>

Status values: `proposed`, `applied`, `rejected`, `recurring`. A `rejected` entry is never re-proposed without new evidence. A `recurring` entry marks an applied mitigation that failed to stop the friction, so the next proposal targets a stronger mitigation.

Phase 0 reads this file, if it exists, before the clarification rounds and folds its open, relevant entries into the rounds, so historically frictional points surface in round 1 instead of mid-loop. Brief composition reads it when a known pitfall bears on a worker's task (see `SKILL.md`).

## Exit retrospective

Run on every exit: the phase-8 report and every stop-rule report (round cap, no-progress circuit breaker, exhausted budget). A failed loop's friction data is the most valuable, so never skip the retrospective because the loop failed.

1. Aggregate the effort log: count rows per bucket and total the cost in question round trips, worker dispatches, and rework rounds. Never estimate tokens; a round trip and a wasted dispatch are the real costs.
2. Root-cause each high-cost row to exactly one improvement target through the bucket mapping above.
3. Rank proposals by expected saving: frequency (this log plus the backlog) times cost per occurrence.
4. Drop any proposal with no evidence row behind it; a speculative rewrite of instructions is itself friction.
5. Report the ranked list to the human in the exit report (each entry naming the exact target file and the proposed change) and append the entries to the backlog.

## Guardrail

The supervisor proposes, never applies. The agent doing the work never grades it, and an agent never improves its own instructions unilaterally: improvements to instructions, skills, or agent definitions land only on human direction (a manual edit or a follow-up loop run in the dotfiles repository).

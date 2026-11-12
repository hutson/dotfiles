---
description: Re-evaluate agent model assignments against the OpenCode Go catalog and the last month of real usage; proposes options, then applies the one I choose.
agent: plan
subagent: false
---

Re-run the periodic model evaluation for the agent team in `.config/opencode/opencode.jsonc`. Goal: confirm or adjust every agent's model and effort variant so each agent runs the most appropriate model available on the OpenCode Go subscription, while keeping metered monthly usage just under $10.

Work in two phases. Phase 1 gathers evidence and proposes 2-3 complete options; edit no files during Phase 1. Phase 2 applies the option I choose. If I have not chosen an option, stop after Phase 1.

$ARGUMENTS may narrow the scope (for example one agent to re-examine) or override the budget target.

## Phase 1: Gather evidence

1. Current state. Read `.config/opencode/opencode.jsonc`, including each agent's inline rationale (goal, Model/Comparison/Leaderboard links, benchmark ranks, trade-off notes) and any documented promotion triggers (for example "promote back to MiMo-V2.6-Pro if re-adjudication rounds rise"). Test those triggers against the new data instead of blindly re-picking winners.

2. Real usage, last 30 days. Query the OpenCode session database at `${XDG_DATA_HOME:-$HOME/.local/share}/opencode/opencode.db` (SQLite, read-only). Message rows carry a JSON `data` column with `agent`, `model.{providerID,id,variant}`, `cost`, and `tokens.{input,output,reasoning,cache.read,cache.write}`; timestamps are Unix epoch milliseconds. Report per agent and per model variant: message counts, token mix, and estimated cost. Recorded `cost` can be stale or zero for recent rows (it has stopped tracking before), so when in doubt price the tokens at the Go catalog rates instead of trusting the recorded cost. Watch for variant drift (sessions may run a different `#effort` than the config declares) and for heavy single days that stress the 5h and weekly allowance windows.

3. Plans and progress. Read plan files under `~/.opencode/plan`, then every `~/.data/opencode/progress/` goal file updated in the last month: extract "Effort log" rows, `*-stage-usage.json` sidecars, and the `## Stage usage` records in `loop-improvements.md`. Classify each recorded failure as capability-driven (a stronger or different model plausibly helps) or process-driven (briefs, environment, tooling; model choice will not fix it). Only capability-driven evidence should move models; report the process-driven waste separately as non-model findings.

4. Catalog research. Fetch https://opencode.ai/docs/console/go/#models (model list, per-token prices, per-model monthly allowances, effort variants, the privacy table for retention and training, region notes) and https://opencode.ai/docs/console/go (window mechanics: 5h = 20% and weekly = 50% of the monthly allowance). Record models added, removed, repriced, or policy-changed since the last evaluation.

5. Benchmark research. For every candidate model, collect llm-stats leaderboard standings (reasoning, coding, tool calling, writing; the writing index covers no Go model, so use instruction following as its proxy), the head-to-head pages at https://llm-stats.com/models/compare/<a>-vs-<b> for trade-offs between substitutable models, and models.dev spec pages. Carry the score, rank, and source URL for every claim.

## Decision rules (priority order)

1. Security first: the security agent keeps the strongest model its constraints allow; its quality takes priority over cost.
2. Grading/verifier agents (documentation, quality-assurance, security, test-design) must not share a model vendor with implementation agents (architect, developer, build); vendor means the model family (Xiaomi, Zhipu, Alibaba, and so on), not the `opencode-go` provider.
3. Avoid any model with a data-retention period or that trains on request data.
4. Prefer open-weight models; a closed-weight choice needs a documented trade-off.
5. Every agent's model must score well for that agent's purpose, with cited benchmarks.
6. Metered monthly usage at list prices lands just under $10 at the last-30-day traffic, and every model stays inside its Go monthly allowance and the 5h/weekly windows.

## Phase 1 output

Present 2-3 complete options. For each option list every agent in this config with: current model, proposed model and variant, what changed, why (cited benchmark ranks plus the leaderboard/comparison URL), and the trade-off whenever the pick is a compromise (the form: chosen over Model B despite B's better score, because of cost, vendor separation, or policy). Close each option with the estimated metered monthly cost against the $10 target, per-model allowance headroom, and the risks (pricing cliffs, expiring zero-retention agreements, region requirements). Recommend one option with a short justification. Scope is the agents defined in this config; if session data reveals other agents (project-level definitions), note them without proposing changes.

## Phase 2: Apply (only after I choose an option)

1. Update `.config/opencode/opencode.jsonc`: set each chosen `model` string with its explicit `#effort` variant, and rewrite that agent's inline comment block (goal, models.dev Model link, llm-stats Comparison and Leaderboard links, benchmark scores, trade-off notes). Match the existing comment style and never leave a "Why this model?" TODO behind.
2. Verify every cited URL resolves before finishing.
3. Validate with the project's single test entry point until it passes: `devsy ci . -- bash .tools/test.sh` (or `bash .tools/test.sh` when already inside the Dev Container).
4. Finish with a summary of what changed versus the previous month and which documented promotion triggers to watch before the next run.

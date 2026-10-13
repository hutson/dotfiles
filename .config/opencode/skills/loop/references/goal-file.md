# Goal/state file format

Write to `~/.opencode/progress/<project>-<slug>.md`. One file per loop. Update it in place.
The `supervisor` agent owns this file: a session under Plan-mode restrictions cannot write
outside the plan directory, so the loop never maintains state as `plan` (see the skill's
Plan-mode guard).

    # Loop: <slug>
    - Objective: <the testable goal>
    - Acceptance criteria: <observable outcomes, mechanically checkable>
    - Constraints: <the phase-0 answers that shape the deliverable (stack, interface
      surface, invocation and distribution, presentation) plus any answer inferred from
      the request or repo instead of asked, so fresh workers brief from it and the human
      can correct the assumption>
    - Test authoring: <the human's one-time consent from phase 0 to add and update tests for the criteria above>
    - Must not break: <regression boundary>
    - Verify: <the single test entry point command, taken from the project's readme.md>
    - Stop rule: tests green AND new-code coverage >= 70% AND all graders PASS, max 4 rounds
    - Human review required before touching: <billing, auth, migrations, ...>
    - Already tried: <what failed and why, so fresh workers do not repeat it>

    ## Plan
    1. <ordered step: worker -> deliverable>

    ## Design
    <architect output; no lines of code>

    ## Test baseline
    Append-only log of revision blocks; a prior revision is never edited. Record revision 1
    at step 5 on PASS; append a later revision only after a verified sanctioned change or
    human direction; quality-assurance verifies the newest revision before every run.

    ### Revision <n>
    - Recorded: <stamp> (<reason: step-5 endorsement | sanctioned test change | human
      direction>)
    - Sanction: <the test-design verdict line naming the exact file-level delta and the
      acceptance criterion it preserves, or the human direction; a developer return is
      never a sanction; revision 1's sanction is the step-5 test-design PASS verdict>
    - Inventory: <path-prefix patterns over the full test surface: test directories, test
      tooling, fixtures, static-analysis config>
    - Digest algorithm: sha256
    - Files: <one `path` + `digest` line per inventoried file>
    - Verify: <the recorded single test entry point command>
    - Applied digests: <note that the supervisor read the changed test files and verified
      the applied state matches the sanction, before this revision was appended; revision
      1's note reads "initial baseline">
    - Snapshots: <slug>-baseline/, a supervisor-written-only subdirectory of the progress
      path holding the content of every inventoried file; each re-baseline refreshes it in
      full to match the appended revision, so prior content persists only in the digest log

    ## Status
    - PASS|FAIL <check>: <reason>   (one line per check, updated each round)
    - Round <n>: <gate entered> -> <gate that failed, or chain PASS> | files changed: <list>
      (one line per round, so the round cap and the no-progress circuit breaker recount
      deterministically after /resume)

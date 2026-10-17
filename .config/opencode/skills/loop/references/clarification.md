# Phase-0 clarification checklist

You are the product developer at the start of the loop. Your job is to understand the human's goal well enough that the first delivered pass solves their need and leaves them happy with the outcome. A clarifying question costs one round trip; a wrong assumption costs a wasted implementation pass, and the human pays for it twice (the loop's worker dispatches plus a re-do). So the walkthrough below is thorough by default.

## Question categories

Cover each category, asking the questions whose answers change what gets built:

1. Goal and success: what problem does this solve, for whom, and what does "done" look like from the human's point of view. The objective and the acceptance criteria come out of this answer, so start here.
2. Behavior and boundaries: the values the deliverable accepts and produces (ranges, defaults, edge cases, invalid input). For "display a random number", the number range is a boundary question.
3. Interface surface: where the human sees the result (standard output, a TUI, a GUI, a file, a web page). Surface decides the design more than almost anything else, so ask it early.
4. Invocation and distribution: how the human will run it (`go run` in a folder, an installed binary, a published package) and, if published, what it is named and how it is versioned. Invocation decides the build layout and metadata.
5. Stack and toolchain: programming language, versions, and dependency policy when the human cares. If the request leaves the language open, ask; the default answer (the repo's existing language) is an assumption, not a given.
6. Conventions and templates: an existing project to use as a template, the style to mirror, or scaffolding to reuse. This is where a human's real workflow often lives. When the request implies a fresh project (an empty or near-empty folder), the `scaffold` skill is the house convention: offer it as the recommended option, confirm its stacks and goals, and ask only whether a personal template takes precedence.
7. Presentation (conditional): how output should look on screen (color, font, animation, layout). Ask this only when the interface surface is interactive; a plain stdout-only tool rarely needs it.
8. Failure behavior: what happens when the input is wrong or a dependency is missing (error messages, exit codes). Testable criteria depend on this.
9. Platform and environment: target operating systems, terminals, and other environment constraints that change the implementation.
10. Scope boundaries: what the human deliberately does not want built, so the loop does not gold-plate.
11. Acceptance and verification: how correctness gets checked. This is where the loop's `Verify` command and the test authoring consent from SKILL.md phase 0 live, so confirm them in this walkthrough rather than as a separate interruption. When the project has no `readme.md` yet and the `scaffold` skill applies, do not ask the human to invent a command: `bash .tools/test.sh` (the scaffold's single entry point, its gates assembled from the stack skills' `Verify` sections) is the recommended answer, and the scaffolding pass writes the readme that documents it.

## Asking rules

- Use the `question` tool, not prose. Batch the questions for one round into a single call so the human answers them together.
- Ask in phased rounds, ordered by impact. Round 1 covers the categories that reshape the deliverable: goal and success, behavior and boundaries, interface surface, invocation and distribution, stack and toolchain, and conventions and templates. Later rounds follow conditional branches only when an earlier answer triggers them, such as the presentation categories after a TUI or GUI answer. This keeps the human from answering questions that may not apply.
- For each question, offer concrete options and put the recommended default first with "(Recommended)" in its label. The tool adds a free-form answer on its own, so do not add a catch-all option for it.
- Skip a category when the request, the repo, or the project's `readme.md` already answers it, but do not drop the answer: record what you inferred in the goal file's `Constraints` line as an assumption the human can correct. Never ask for something you could learn by reading the repository first.
- Stop the walkthrough as soon as the objective and acceptance criteria are testable and every answer that changes the deliverable is known or recorded as an assumption. The goal is a confident first pass, not an interrogation.
- Record the answers (and assumptions) in the goal file so fresh workers brief from them and the human can see what the loop thinks it is building.

## Worked example

Goal: "implement a cli that displays a random number." A seasoned product developer does not implement immediately; the request leaves too much open. Round 1, asked together with the `question` tool:

- Do you have a number range in mind? (behavior and boundaries)
- Should this print to standard output, or display in a TUI interface? (interface surface)
- If no language is specified, which language would you prefer this written in? (stack)
- Do you have any existing project I should use as a template? (conventions)
- How do you want to invoke this CLI? Directly in the folder via `go run`, or do you plan to publish it somewhere eventually? (invocation and distribution)

Round 2 follows only on the answers. If the human chose a TUI, ask the presentation questions (color, font, animation, etc.). If standard output, skip them. Either round ends by confirming the `Verify` command and the test authoring consent.

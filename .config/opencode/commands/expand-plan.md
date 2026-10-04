---
agent: plan
description: Expand a high-level plan into a detailed implementation plan document for handoff to another agent.
subagent: false
---

Expand the high-level plan below into a detailed implementation plan document that another agent can execute without access to this conversation.

High-level plan:

$ARGUMENTS

If the high-level plan above is empty, use the plan discussed in this conversation. If there is none, ask me for it before writing anything.

Structure the document with these sections in order:

1. Ground truth: verified facts the implementation relies on (current behavior, exact outputs, versions), each traceable to evidence rather than assumption.
2. Acceptance criteria: observable outcomes that prove the work is correct, specific enough to check mechanically.
3. Investigation: read-only steps that resolve open facts before coding, with exact commands.
4. Implementation: numbered stages naming the exact files to change and the exact identifiers, strings, and logic to use.
5. Constraints for the implementing agent: applicable project rules plus explicit do-not items that prevent foreseeable mistakes, including side-effecting commands that must not run without asking first.
6. Validation: how to prove correctness, in order, with the commands to run and the output to expect.

Before writing the document, verify rather than guess. Read the relevant code, configuration, and authoritative documentation for any external tools involved (upstream docs or source), and collect the exact file paths, identifiers, command outputs, and strings the plan will reference. Where a fact cannot be verified before implementation, open the plan with a read-only investigation step that produces it.

Wherever more than one coding strategy could achieve a goal, choose one and state the criterion that selected it, the fallback if it fails that criterion, and how the implementation agent will verify which situation applies. Do not leave the choice open.

Write the document to ~/.opencode/plan/<slug>.md where <slug> includes a timestamp appended by a short kebab-case summary of the topic. If that file already exists, delete it. Write nowhere else. Writing the plan file with your write tool is the deliverable of this task, not an implementation step. Do the write before replying and do not defer it to another agent. Reply with only the file path and one line per stage.


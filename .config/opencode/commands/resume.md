---
description: Load the most recent goal/state file and continue the loop from where it left off.
agent: supervisor
subagent: false
---

Read the most recent goal/state file under ~/.opencode/progress/ for this project, summarize where the loop stands (objective, plan, status, already-tried), load the `loop` skill, and continue from the first unfinished phase. Ask me before doing anything the file marks as needing human review.

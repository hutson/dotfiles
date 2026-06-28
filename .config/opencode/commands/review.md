---
agent: plan
description: Review pending changes and suggest improvements.
subtask: false
---

Review all pending and staged changes in this working directory with the help of the following agents:

- @reviewer-security if the changes included any changes to code, or to LLM-related Markdown files, including agents and `AGENTS.md`.
- @reviewer-go if the changes include any Go language files.
- @reviewer-documentation if the changes included any changes to code, addition/modified of code comments, or the addition/modified of documentation files such as Markdown or AsciiDoc.
- @reviewer-test-design if changes included new or modified test files.

Take the feedback from the agents and create a plan to implement the improvements. Not all suggestions for improvement will be worth the risk or complexity. Based on your understanding of the current project, and instructions you have received from me, take a conservative approach to preemptively exclude any low value improvements that are high risk.

Ask for clarification where clarification may help exclude additional unnecessary recommendations or where my input can help create a more correct implementation plan.

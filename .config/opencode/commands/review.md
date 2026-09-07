---
agent: plan
description: Review the staged, unstaged, and untracked, files witin the current working directory with the assistance of specialized sub-agents and suggest improvements.
subtask: false
---

The current working directory is a source code repository. You will create a plan to make improvements to this repository's staged file changes, unstaged file changes, and files listed as untracked, by dispatching those files to specialized sub-agents. Those sub-agents will provide you a list of suggestions for improvements along with a justification for each suggestion. You do not have to call every sub-agent. Review the description for each sub-agent and dispatch a limited set of files to each sub-agent if that sub-agent is designed to support those files.

- @reviewer-security if the changes included any changes to code, or to LLM-related Markdown files, including agents and `AGENTS.md`.
- @reviewer-go if the changes include any Go language files.
- @reviewer-documentation if the changes included any changes to code, addition/modified of code comments, or the addition/modified of documentation files such as Markdown or AsciiDoc.
- @reviewer-test-design if changes included new or modified test files.

Take the feedback from the sub-agents and create a plan to implement improvements. Not all suggestions for improvement will be worth the risk or complexity. Based on your understanding of the current project, and instructions you have received from me, take a conservative approach and preemptively exclude any low value improvements that are high risk.

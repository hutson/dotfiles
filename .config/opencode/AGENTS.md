## Priority

When rules conflict, apply them in this order:

1. Security (never expose secrets, validate inputs)
2. Correctness (tests pass, code works as intended)
3. Simplicity (smallest change, fewest moving parts)
4. Convention (match existing patterns and style)

## General Rules

- Make the smallest number of changes to complete the task.
- Break down complex solutions into individual steps.
- When improving code, make the best choice directly. Only present alternatives when the trade-offs involve subjective preferences the user should decide (e.g., performance vs. readability, library A vs. library B).
- When encountering ambiguity, or when instructions are in conflict with one another, ask the user to clarify.
- Use lowercase when creating readme files: `readme.md`
- Read the project's `readme.md` file for testing and validation instructions, and if those instruction might be related to files you have modified, run those instructions in a loop, making changes to files until instructions pass.
- Never consider, comment, or carry out the action of, staging changes, committing changes, pushing code, or opening pull requests. Those will only ever be done by the user as the user's discretion.
- Delegate code exploration that spans multiple files or covers an unfamiliar area of the codebase to the `explore` sub-agent; it returns a summary, which keeps your context small. Handle single reads, greps, and targeted lookups yourself, since dispatching a sub-agent costs a round trip. Never delegate grading, review, or verification of your own work to a sub-agent: a sub-agent's opinion is neither a deterministic check nor a fresh grader's verdict.
- Prefer tool settings in configuration files over command-line flags.
- Identify the languages, tools, and frameworks the work touches, and load the matching skill (for example `go`, `bash`, `ansible`, `devcontainer`, `docs`) before acting. Read only the reference section relevant to your role. If no skill exists for a stack in use, follow general best practices and note that a skill should be created for it.

## Code Style Rules

- Use tabs for indentation unless a file is indented using spaces.
- Use meaningful and readable function and variable names that describe the purpose and form a sentence:

```bash
if isAuthorized(username) {
    // do something
}
```

Not:

```bash
if authcheck(u) {
    // do something
}
```

## Testing Rules

- Testing falls into one of two categories: static analysis (linters and analyzers) and dynamic tests that execute project code.
- Never invent custom test tooling, lint tooling, or coverage metrics. If the project's standard test entry point does not offer a way to exercise the required testing, suggest several standard tooling options to the user to pick from.

Static analysis:

- Never remove a TODO comment from code without approval, even if it fails a static linter.
- If a TODO is found and fails, review the linter that failed and add an inline code comment that ignores that rule for that TODO comment.

Dynamic tests:

- Only implement offline tests. Tests should never require network access to install dependencies or execute tests.
- When creating or expanding tests in a project, prefer implementing unit and integration tests on your own, but present the user options for implementing end-to-end tests so they can choose whether the complexity is worth the value.
- Tests must be non-destructive such that repeated runs must not fill the disk, permanently delete files, or mutate source files.
- Tests must be fast, with individual test cases completing under a second and the whole test entry point taking less than 30 seconds. If closing a coverage gap would take more than about 5 seconds, drop the test and add a multi-line `TODO:` comment describing the gap, how a test could cover it, and why speed forced the omission.

## Documentation Rules

- Do not use hard word wraps in new files, and do not introduce them in existing files, unless hard wrapping is the convention in that file (follow the wrapping style a file already uses).
- When editing or rewriting a comment, always preserve the rationale (the "why") even if the phrasing is shortened.
- Do not add comments that explain what is happening or how it is happening.

```go
rectangleArea := width * height // Calculate rectangle area.
```

- Prefer comments that explain details about the code that are not self-explanatory:

```bash
brew upgrade --greedy # Upgrade all Brew-installed packages, including those that manage their own upgrades through auto-updates (--greedy).
```

- Prefer comments that compare the current implementation against alternatives, demonstrating why this approach is best for the situation or user.

```bash
brew cleanup --scrub --prune=all # Remove old/outdated downloads and formulae, along with purging the cache, to free up disk space. The cache could improve performance in future upgrades, but this optimizes for reducing disk space usage, which is a bigger constraint in the containerized environments where we use Homebrew.
```

- Prefer placing a very long trailing comment on its own line, above the code or content the comment is referencing.

```bash
# Remove old/outdated downloads and formulae, along with purging the cache, to free up disk space. The cache could improve performance in future upgrades, but this optimizes for reducing disk space usage, which is a bigger constraint in the containerized environments where we use Homebrew.
brew cleanup --scrub --prune=all
```

- Use multi-line comments when inline comments appear too long to fit onto a single line on the user's screen, or when documenting a multi-line code block.

```bash
# Remove old/outdated downloads and formulae, along with purging the cache, to 
# free up disk space. The cache could improve performance in future upgrades, but
# this optimizes for reducing disk space usage, which is a bigger constraint in
# the containerized environments where we use Homebrew.
brew cleanup --scrub --prune=all
```

- Do not use em dashes in your writing.

```
this — or that - thing
```

- Prefer surrounding text using paranthesis.

```
this (or that) thing
```

## Security Rules

- Sanitize and validate all user inputs.
- When introducing new packages, or migrating a project to a new package manager, always prefer the use of lockfiles, or if lockfiles are not supported, prefer pinning a version to a specific commit hash or content hash.

## Dotfiles Rules

- Follow XDG Base Directory specification: use `XDG_CONFIG_HOME` for configuration files, `XDG_DATA_HOME` for data files, and `XDG_CACHE_HOME` for cache files.
- Organize configuration into modular, single-purpose files rather than monolithic configuration files for easier maintenance and version control.

## General Logging Rules

For general purpose programming languages; when implementing logging, or refactoring to update a project to follow logging best practices, adhere to these rules.

- Send log output to `stderr` by default.
- Use `DEBUG` environment variable to determine when to enable or disable logging. The `DEBUG` environment variable must be set to enable logging. The value is the package name; e.g., `codeberg.org/hutson/semantic-tag/semantictag`.
- The `DEBUG` environment variable may include multiple packages delimited using commas; `DEBUG=pkg1,pkg2`.
- The `DEBUG` environment variable may enable all packages using `*`; `DEBUG=*`.
- The `DEBUG` environment variable supports wildcard suffix; `DEBUG=codeberg.org/hutson/*` enables all packages under that path.
- Use `LOG_LEVEL` environment variable to determine the minimum severity level, following RFC 5424; `emerg`, `alert`, `crit`, `err`, `warning`, `notice`, `info`, `debug`. Default is `warning` if not set.

Logging from a command line tool may look like:

```bash
DEBUG=codeberg.org/hutson/semantic-tag/semantictag LOG_LEVEL=debug cli-tool`
```

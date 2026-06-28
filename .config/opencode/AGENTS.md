## General Rules

- Make the smallest number of changes to complete the task.
- Break down complex solutions into individual steps.
- When there are 2 or more possible solutions to a problem, explain the trade-offs of each solution and ask the user which option they prefer.
- When encountering ambiguity, or when instructions are in conflict with one another, ask the user to clarify.
- Read the project's `readme.md` file for testing and validation instructions, and if those instruction might be related to files you have modified, run those instructions in a loop, making changes to files until instructions pass.
- Never consider, comment, or carry out the action of, committing changes, pushing code, or opening pull requests. Those will only ever be done by the user as the user's discretion.

## Code Style Rules

- Follow the project's existing code style and conventions.
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

## Bash Scripting Rules

- Prefer the full argument name when passing flags to commands (e.g., use --help instead of -h), though be mindful that many command on MacOS only support the short-hand version.
- Always use double quotes around variable expansion to prevent word splitting and globbing; `"$speed"`
- Always use curly brackets around variable expansion to avoid ambiguity; `"${speed}mph"` when the variable is `$speed`
- Always use `$(...)` for command substitution instead of backticks (`...`).
- Prefer POSIX-compliant syntax, such as `test` or single `[` brackets, to improve portability across different Unix-like operating systems.
- Use defensive shell scripting best practices: such as `set -euf -o pipefail` at the start of bash scripts for safety, an avoid the use of `eval`.

## Testing Rules

- Never modify tests unrelated to the code that is added or modified.
- Always ask to add or update tests for new or modified code.
- Prefer running only those test cases that cover the funtionality that was added or modified.
- Added or modified functionality includes all uncommitted changes in the local project, regardless of whether those changes were made in the current session.

## Documentation Rules

- When editing or rewriting a comment, always preserve the rationale (the "why") even if the phrasing is shortened.
- Do not add comments that explain what is happening or how it is happening.

```go
rectangleArea := width * height // Calculate rectangle area.
```

- Prefer comments that explain details about the code that are not self-explanatory:

```bash
brew upgrade --greedy # Upgrade all Brew-installed packages, including those that manage their own upgrades through auto-updates (--greedy).
```

- Or prefer comments that compare the current implementation against alternatives, demonstrating why this approach is best for the situation or user.

```bash
brew cleanup --scrub --prune=all # Remove old/outdated downloads and formulae, along with purging the cache, to free up disk space. The cache could improve performance in future upgrades, but this optimizes for reducing disk space usage, which is a bigger constraint in the containerized environments where we use Homebrew.
```

- Use multi-line comments when inline comments appear to long to fit onto a single line on the user's screen, or when documenting a multi-line code block.

```bash
# Remove old/outdated downloads and formulae, along with purging the cache, to 
# free up disk space. The cache could improve performance in future upgrades, but
# this optimizes for reducing disk space usage, which is a bigger constraint in
# the containerized environments where we use Homebrew.
brew cleanup --scrub --prune=all
```

## Security Rules

- Avoid using hardcoded sensitive information such as passwords or API keys in the code.
- Sanitize and validate all user inputs.
- When introducing new packages, or migrating a project to a new package manager, always prefer the use of lockfiles, or if lockfiles are not supported, prefer pinning a version to a specific commit hash or content hash.

## Dotfiles Rules

- Follow XDG Base Directory specification: use `XDG_CONFIG_HOME` for configuration files, `XDG_DATA_HOME` for data files, and `XDG_CACHE_HOME` for cache files.
- Organize configuration into modular, single-purpose files rather than monolithic configuration files for easier maintenance and version control.

## Go Project Creation Rules

- When creating a new Go project, `go.mod` should use the oldest supported version of Go, 1.25.0, for the `go` directive, separate from the value of toolchain, to ensure our Go module is compatible with all supported versions of Go.

## Go Testing Rules

- Prefer calling the `go test` command using the following format to ensure we are failing quickly on the first failure to avoid wasting time on bad tests, testing for race conditions in the code, and are further testing that there are no code paths that require a particular number of processor cores to work correctly.

```go
go test -failfast -race -cpu=1,24 -cover -coverprofile=coverage.out
```

- When updating only part of an existing project, and the test case for that part of the code is known, use `-run` during development to reduce the time it takes to get feedback, but exclude `-run` when ready to validate the work is done.

## Ansible Rules

- Use `ansible.builtin.assert` for validation checks instead of `fail` with `when` conditions.
- Prefer simplicity - avoid complex backup/rollback systems unless data cannot be recreated.
- Make tasks idempotent - check state before running commands (e.g., check if a file exists before running a command that creates it).
- When reviewing code, ask about removing unlikely edge case handling rather than preserving complexity.
- Validate inputs early (preflight checks) but let Ansible modules fail naturally rather than duplicating their validation logic.
- For non-critical data backups, or when creating/writing temporary files and directories, use OS temp directories and let the OS clean up automatically.

## Logging Rules

When implementing logging, or refactoring to update a project to follow logging best practices, adhere to these rules.

- Log output to `stderr` by default.
- Use `DEBUG` environment variable to determine when to enable or disable logging. The `DEBUG` environment variable must be set to enable logging. The value is the package name; e.g., `codeberg.org/hutson/semantic-tag/semantictag`.
- The `DEBUG` environment variable may include multiple packages delimited using commas; `DEBUG=pkg1,pkg2`.
- The `DEBUG` environment variable may enable all packages using `*`; `DEBUG=*`.
- The `DEBUG` environment variable supports wildcard suffix; `DEBUG=codeberg.org/hutson/*` enables all packages under that path.
- Use `LOG_LEVEL` environment variable to determine the minimum severity level, following RFC 5424; `emerg`, `alert`, `crit`, `err`, `warning`, `notice`, `info`, `debug`. Default is `warning` if not set.

Logging from a command line tool may look like: `DEBUG=codeberg.org/hutson/semantic-tag/semantictag LOG_LEVEL=debug cli-tool`

## Dev Container Rules

- Use the `vscode` user (Microsoft convention) for interactive development, not `linuxbrew` or custom names.
- Match host UID/GID at build time via `build.args` when using tools that do not implement `updateRemoteUserUID`.
- Use `remoteUser` for dev tools and lifecycle hooks; do not set `containerUser` to a non-root user.
- Use spec-compliant properties (`capAdd`, `securityOpt`) instead of Docker-specific `runArgs`.
- Security relaxations (like `capAdd` and `securityOpt`) are acceptable for dev containers but must be documented with inline comments explaining the accepted risk.
- Keep the container's default user as `root` for orchestrator setup, then drop to `remoteUser` for dev work.

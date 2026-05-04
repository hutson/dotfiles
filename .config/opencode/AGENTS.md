## General Rules

- Make the smallest number of changes to complete the task.
- Break down complex solutions into individual steps.
- When there are 2 or more possible solutions to a problem, explain the trade-offs of each solution and ask the user which option they prefer.
- When encountering ambiguity, or when instructions are in conflict with one another, ask the user to clarify.
- If project scope or commands need to be executed to validate correctness of changes, read the project's `readme.md` file for testing intructions.
- Never commit or push code using `git` or other source control tool.

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

- Avoid introducing single line comments that explain what is happening or how it's happening.
- Instead, prefer introducing multi-line comments that explain why code was written a particular way, but only if there were alternative approaches considered, or when the code is not self-explanatory/documenting.

## Security Rules

- Avoid using hardcoded sensitive information such as passwords or API keys in the code.
- Sanitize and validate all user inputs.
- When introducing new packages, or migrating a project to a new package manager, always prefer the use of lockfiles, or if lockfiles are not supported, prefer pinning a version to a specific commit hash or content hash.

## Dotfiles Rules

- Follow XDG Base Directory specification: use `XDG_CONFIG_HOME` for configuration files, `XDG_DATA_HOME` for data files, and `XDG_CACHE_HOME` for cache files.
- Organize configuration into modular, single-purpose files rather than monolithic configuration files for easier maintenance and version control.

## Go Compiler Rules

- Always prefer building and testing against the lastest Go toolchain.
- Ensure `go.mod` is setup to prefer the oldest supported version of Go, separate from the value of toolchain, to ensure our Go module is compatible with all supported versions of Go.

## Go Testing Rules

- Prefer calling the `go test` command using the following format to ensure we are building against the lastest toolchain version, failing quickly on the first failure to avoid wasting time on bad tests, testing for race conditions in the code, and are further testing that there are no code paths that require a particular number of processor cores to work correctly.

```go
GOTOOLCHAIN=[VERSION] go test [PATH] --fail fast -race -cpu=1,24 -run [TEST]
```

## Ansible Rules

- Use `ansible.builtin.assert` for validation checks instead of `fail` with `when` conditions.
- Prefer simplicity - avoid complex backup/rollback systems unless data cannot be recreated.
- Make tasks idempotent - check state before running commands (e.g., check if a file exists before running a command that creates it).
- When reviewing code, ask about removing unlikely edge case handling rather than preserving complexity.
- Validate inputs early (preflight checks) but let Ansible modules fail naturally rather than duplicating their validation logic.
- For non-critical data backups, or when creating/writing temporary files and directories, use OS temp directories and let the OS clean up automatically.

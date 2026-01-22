## General Rules

- Make the smallest number of changes to complete the task.
- Do not add short explanations or justifications as inline comments in generated code.
- Review the current repository's `readme.md` files, if it exists, for an overview of the project.

## Bash Scripting Rules

- Always use the full argument name when using commands (e.g., use --help instead of -h).
- Use double quotes around variable expansions to prevent word splitting and globbing.
- Use $(...) for command substitution instead of backticks (`...`).

## Testing Rules

- Prefer running single test cases or files instead of the entire test suite when possible.

## Code Style Rules

- Follow the project's existing code style and conventions.

## Security Rules

- Avoid using hardcoded sensitive information such as passwords or API keys in the code.
- Sanitize and validate all user inputs to prevent security vulnerabilities.

## Dotfiles Rules

- Follow XDG Base Directory specification: use `XDG_CONFIG_HOME` for configuration files, `XDG_DATA_HOME` for data files, and `XDG_CACHE_HOME` for cache files.
- Use defensive shell scripting practices: always include `set -euf -o pipefail` at the start of bash scripts for safety.
- Organize configuration into modular, single-purpose files rather than monolithic configuration files for easier maintenance and version control.

## Go Compiler Rules

- Always prefer building and testing against the lastest toolchain.
- Ensure `go.mod` is setup to prefer the oldest supported version of Go, separate from the value of toolchain, to ensure our Go module is compatible with all supported versions of Go.

## Go Testing Rules

- Prefer calling the `go test` command using the following format to ensure we are building against the lastest toolchain version, failing quickly on the first failure to avoid wasting time on bad tests, testing for race conditions in the code, and are further testing that there are no code paths that require a particular number of processor cores to work correctly.

```go
GOTOOLCHAIN=[VERSION] go test [PATH] --fail fast -race -cpu=1,24 -run [TEST]
```

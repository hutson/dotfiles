import type { Plugin } from "@opencode/plugin";

// TODO: The deny/allow boundary in this file has no automated tests, and `biome check`
// cannot type-check it. A test should assert the fixture matrix: `git commit` denied,
// `git log --grep commit` allowed, `git remote -v` allowed, `git reflog expire` denied,
// `| sh -c` denied, `bash file.sh` allowed, `.github/` allowed, `id_rsa` denied,
// `id_rsa.pub` allowed. Extend with the bash-header matrix: `set` preceded only by the
// shebang and comment lines allowed, `set` missing denied, `set` after another statement
// denied. Deferred because the validation environment has no JavaScript
// runtime; once one exists, `node --test` with `node:assert` is the standard offline runner.
const plugin = {
	id: "guardrails",
	async setup(ctx) {
		// Permission layer: a clean `deny` with a reason. The hook runs for allow/ask
		// decisions, so it holds even when an agent's broad `allow` would otherwise win.
		await ctx.permission.hook("evaluate", (event) => {
			// Never commit, push, stage, or otherwise mutate the repository: human-only actions, with
			// `rm`/`mv` included because they also stage. Read-only forms of multi-mode verbs stay allowed
			// where git's grammar separates them (`git remote -v`, `git stash list`, `git tag -l`);
			// `git config` stays denied entirely because its read and write forms differ only in argument
			// count, and a bare `git branch <name>` write cannot be separated from listing, so bare branch
			// creation escapes as an accepted gap (`fetch` and `notes` are absent from the verb list because
			// the loop legitimately needs them). The pattern
			// is unanchored so wrappers that keep the verb visible in the command text (`sh -c`, `eval`,
			// `xargs`, `&&` chains) are denied by the same match; the optional quote or expansion marker
			// before the verb covers quoted variants of it. Flag tokens between the command and the verb
			// are skipped, along with the value of value-taking flags (`-c`, `-C`, `--git-dir`,
			// `--work-tree`, `--namespace`); the bare-flag alternative refuses those flags so each token
			// run partitions uniquely (an ambiguous star over `-C`-style tokens caused exponential
			// backtracking). Skipping arbitrary flag-and-value pairs instead would false-positive on
			// read-only commands whose own flags take values (for example `git log --grep commit`). Verbs
			// hidden from a text scan (variable expansion, `./script.sh`) still escape; only a strict
			// shell allowlist closes that, at the cost of the arbitrary toolchains the engineering loop
			// needs to run.
			const gitWrite =
				/\bgit\s+(?:(?:-[cC]|--git-dir|--work-tree|--namespace)\s+\S+\s+|(?!(?:-[cC]|--git-dir|--work-tree|--namespace)\s)-\S+\s+)*["'`$]*(commit|push|add|update-index|credential[a-z-]*|rm|mv|remote\s+(?:-\S+\s+)*(?:add|remove|rename|set-url|set-head|set-branches|prune)|branch\s+(?:-\S+\s+)*(?:-[fdmMDcC]|--force|--delete|--move|--copy|--rename-branch|--set-upstream-to|--unset-upstream|--edit-description)|worktree\s+(?:-\S+\s+)*(?:add|remove|move|prune|repair)|tag(?!\s+(?:-\S+\s+)*(?:-l|--list)\b)|merge|rebase|reset|checkout|switch|restore|stash(?!\s+(?:-\S+\s+)*(?:list|show)\b)|apply|cherry-pick|revert|clean|config|update-ref|symbolic-ref|clone|init|gc|pull|am|prune|filter-(?:branch|repo)|replace|reflog\s+(?:-\S+\s+)*(?:expire|delete|drop))(?![\w-])/;
			// The GitHub CLI prints its stored token through `gh auth token`, like `git credential` above;
			// the JSONC backstop matches command-initial text only, so this unanchored rule also catches
			// `env gh auth` and path-prefixed forms.
			const ghAuth = /\bgh\s+auth\b/;
			// The one wrapper rule: a piped shell's payload never appears in the command text (a
			// decoded or downloaded script), so the verb scan cannot see it. The scanner may split compound
			// commands into per-segment resources, dropping the pipe from any single resource, or pass the
			// full command string, depending on runtime; the first alternative matches a pipe target with an
			// optional path prefix (`| /bin/sh`) or exec wrapper (`| env sh`, `| sudo sh`), and the second
			// matches a leading segment (a bare `bash`, as a pipe feeds one, or an inline-exec flag like
			// `-c`/`-s`). Script execution (`bash file.sh`) stays allowed. Interpreters other than shells
			// (`| python3 -`) and wrappers carrying their own arguments (`| xargs -n1 sh`) escape; widening
			// either list trades those for false positives on ordinary pipes. The first alternative keeps
			// the rule working on runtimes that pass the full command string.
			const pipeToShell =
				/\|\s*(?:[\w./-]*\/)?(?:env|exec|sudo|nohup|xargs|stdbuf)?\s*(sh|bash|zsh|dash|ksh|ash)(\s|$|;|&)|^(sh|bash|zsh|dash|ksh|ash)(\s+-[a-zA-Z]*[cs][a-zA-Z]*(\s|$)|\s*$)/;
			// Denies any command mentioning a `.git/` path, not only redirections: redirection, `cp`,
			// `touch`, and `tee` all write through the same text, and the required slash keeps `find -name
			// .git` style pruning and `.github/` paths allowed; case-insensitive matching covers
			// case-insensitive filesystems, where `.GIT/` is the same directory.
			const gitPath = /\.git\//i;

			if (event.action === "shell") {
				// One message per rule: what matched, why it is restricted, and what
				// to do instead, so the rejection text alone is enough to course-correct.
				const gitWriteHit = firstMatch(event.resources, gitWrite);
				if (gitWriteHit !== undefined) {
					event.effect = "deny";
					event.message =
						`'${gitWriteHit[0].trim()}' mutates the repository and is human-only (guardrails): agents never stage, commit, push, or otherwise alter the repository. ` +
						"Read-only git commands are allowed; ask the user to run the mutation.";
					return;
				}
				const pipeHit = firstMatch(event.resources, pipeToShell);
				if (pipeHit !== undefined) {
					event.effect = "deny";
					event.message =
						`'${pipeHit[0].trim()}' pipes a payload into a shell for execution (guardrails): the payload never appears in the command text, so the git-write and secret scans cannot police it. ` +
						"Write the script to a file and run it by path (bash file.sh), or ask the user.";
					return;
				}
				const ghHit = firstMatch(event.resources, ghAuth);
				if (ghHit !== undefined) {
					event.effect = "deny";
					event.message =
						"'gh auth' reads stored credentials (guardrails): it prints the access token into command output. Ask the user for the specific value instead.";
					return;
				}
				const gitPathHit = firstMatch(event.resources, gitPath);
				if (gitPathHit !== undefined) {
					event.effect = "deny";
					event.message =
						`'${gitPathHit[0].trim()}' references the Git internals directory (guardrails): shell access there can rewrite repository state or install hooks. ` +
						"Use read-only git commands; ask the user for anything else.";
					return;
				}
				const secretHit = event.resources.flatMap(secretMentions)[0];
				if (secretHit !== undefined) {
					event.effect = "deny";
					event.message = `'${secretHit}' names a secret file in a shell command (guardrails): command output would expose it. Ask the user to run the command if it is genuinely needed.`;
					return;
				}
			}

			// The `edit` action covers write, edit, and patch, so an agent denied commits
			// can still install a hook under the Git directory and have the user's own next
			// commit run it; the boundary above holds only while `.git` stays unwritable.
			// The scan reads paths, not resolved targets, so a symlink into the Git directory
			// or a path built by command substitution still escapes (a strict shell allowlist
			// is the only complete fix, per the note on the verb scan).
			if (event.action === "edit") {
				const gitDirHit = event.resources.find(touchesGitDir);
				if (gitDirHit !== undefined) {
					event.effect = "deny";
					event.message = `Writing into a .git directory is not allowed (guardrails): '${gitDirHit}' could install a hook or config that turns a later allowed command into arbitrary shell. Ask the user to change repository internals.`;
					return;
				}
			}

			// The `.git` deny above does not cover `~/.gitconfig`, which can redirect allowed
			// verbs into arbitrary shell. Escalate to a prompt rather than deny: this
			// repository legitimately manages its own `.gitconfig` dotfile.
			if (
				event.action === "edit" &&
				event.effect === "allow" &&
				event.resources.some(isGitConfigPath)
			) {
				event.effect = "ask";
				event.message =
					"Modifying git configuration needs approval (guardrails): gitconfig can redirect allowed commands into arbitrary shell via core.hooksPath and aliases. Have the user confirm this edit.";
				return;
			}

			if (event.action === "edit") {
				const readmeHit = event.resources.find(isNonLowercaseReadme);
				if (readmeHit !== undefined) {
					const base = readmeHit.split(/[\\/]/).pop();
					event.effect = "deny";
					event.message = `Readme files must be lowercase (guardrails): '${base}' should be 'readme.md'. Re-run the change targeting the lowercase name.`;
					return;
				}
			}

			// Secret shapes the base `.env` guards miss, escalated to a prompt. Policies
			// cannot ask, and each agent's broad `read: * allow` outranks global rules, so
			// this escalation lives in the hook rather than every agent file. It covers
			// editor reads; shell readers (`cat`, `head`) that name a secret path are
			// denied outright above.
			const secretReadHit = event.resources.find(isSecretPath);
			if (
				event.action === "read" &&
				event.effect === "allow" &&
				secretReadHit !== undefined
			) {
				event.effect = "ask";
				event.message = `Reading secret material needs approval (guardrails): '${secretReadHit}' matches a credential file shape. Have the user confirm, or ask them to provide the value.`;
			}
		});

		await ctx.tool.hook("execute.before", (event) => {
			if (
				event.tool !== "write" &&
				event.tool !== "edit" &&
				event.tool !== "patch"
			)
				return;
			const input = (event.input ?? {}) as {
				path?: string;
				content?: string;
				patchText?: string;
			};
			const patchText = input.patchText ?? "";
			const path = input.path ?? "";
			const content = input.content ?? "";

			// Never delete or blank a test file: the code must satisfy the tests, not
			// the reverse. (Weakening or gutting a test, which these checks cannot
			// catch, is graded by `test-design` at step 5 and on demand, on a tripwire
			// fire or a worker signal.)
			if (/\*\*\* Delete File:/i.test(patchText)) {
				const deletedTests = deletedPaths(patchText).filter(isTestPath);
				if (deletedTests.length > 0) {
					throw new Error(
						`Deleting test files is not allowed (guardrails): ${deletedTests.join(", ")}. Code must satisfy the tests, not the reverse; fix the code, or ask the user if a test is genuinely wrong.`,
					);
				}
			}
			if (event.tool === "write" && isTestPath(path) && content.trim() === "") {
				throw new Error(
					`Blanking a test file is not allowed (guardrails): '${path}' would be emptied. Restore its tests; the code must satisfy them.`,
				);
			}

			// Full-content checks run on `write`, where the complete file lands.
			if (event.tool !== "write") return;

			// Bash scripts must opt into safe shell behavior up front.
			if (isBashScript(path, content)) {
				const headerProblem = bashHeaderProblem(content);
				if (headerProblem !== null) {
					throw new Error(
						`'${path}': ${headerProblem} (guardrails: bash scripts must opt into safe shell behavior before any code runs).`,
					);
				}
			}

			// go.mod must carry both a `go` and a `toolchain` directive. This checks
			// structure only and holds no version number, so it cannot drift.
			if (isGoMod(path)) {
				const missingDirectives = [
					/^\s*go\s+\S/m.test(content) ? null : "go",
					/^\s*toolchain\s+\S/m.test(content) ? null : "toolchain",
				].filter((directive) => directive !== null);
				if (missingDirectives.length > 0) {
					throw new Error(
						`'${path}' must include both a 'go' and a 'toolchain' directive (guardrails); missing: ${missingDirectives.join(", ")}. Add them so builds select a pinned toolchain and stay reproducible.`,
					);
				}
			}
		});
	},
} satisfies Plugin.Plugin;

export default plugin;

function isNonLowercaseReadme(path: string): boolean {
	const base = path.split("/").pop() ?? "";
	return /^readme(\.[a-z0-9]+)?$/i.test(base) && base !== base.toLowerCase();
}

// A `.git` path segment anywhere in the target covers a worktree-root Git directory, a
// nested repo's, a `../` relative escape, and a linked worktree's pointer file; matching
// case-insensitively covers case-insensitive filesystems, where `.GIT` is the same directory.
function touchesGitDir(path: string): boolean {
	return path
		.split(/[\\/]/)
		.some((segment) => segment.toLowerCase() === ".git");
}

// Credential shapes beyond the base `.env` guards: OpenSSH key pairs (the `(^|\/)` prefix is
// what lets a bare relative `id_rsa` match; the `$` anchor only requires `id_` names to be a
// final segment, and public `.pub` halves are excluded), the Devsy in-memory secret mount, npm,
// Composer (`auth.json`), and Docker credential files, the gh and git credential stores,
// kubeconfig and Google application-default credentials, the classic `.netrc` and `_netrc`,
// GnuPG's private keyring directory, `.pgpass`, AWS, and PyPI token files, and certificate or
// key containers by extension.
function isSecretPath(path: string): boolean {
	const normalized = path.replace(/\\/g, "/");
	return (
		(/(^|\/)id_[^/]*$/.test(normalized) && !/\.pub$/i.test(normalized)) ||
		/(^|\/)run\/secrets\//.test(normalized) ||
		/(^|\/)\.npmrc$/.test(normalized) ||
		/(^|\/)auth\.json$/.test(normalized) ||
		/(^|\/)\.docker\/config\.json$/.test(normalized) ||
		/(^|\/)\.git-credentials$/.test(normalized) ||
		/(^|\/)gh\/hosts\.yml$/.test(normalized) ||
		/(^|\/)\.netrc$/.test(normalized) ||
		/(^|\/)\.pgpass$/.test(normalized) ||
		/(^|\/)\.aws\/credentials$/.test(normalized) ||
		/(^|\/)\.pypirc$/.test(normalized) ||
		/(^|\/)\.kube\/config$/.test(normalized) ||
		/(^|\/)application_default_credentials\.json$/.test(normalized) ||
		/(^|\/)_netrc$/.test(normalized) ||
		/(^|\/)private-keys-v1\.d\//.test(normalized) ||
		/\.(pem|key|p12|pfx)$/i.test(normalized)
	);
}

// Returns the first regex match across the permission resources, so a denial
// can quote the exact text that tripped the rule.
function firstMatch(
	resources: string[],
	rule: RegExp,
): RegExpMatchArray | undefined {
	for (const resource of resources) {
		const match = resource.match(rule);
		if (match !== null) {
			return match;
		}
	}
	return undefined;
}

// A shell command names a secret in free-form text rather than as one path, so split on shell
// metacharacters and test each token as a path; quotes are stripped so quoted paths still match.
// Returns the offending tokens so a denial can name them.
function secretMentions(command: string): string[] {
	return command
		.split(/[\s;|&()<>=]+/)
		.map((token) => token.replace(/^["'`]+|["'`]+$/g, ""))
		.filter(isSecretPath);
}

// A write here can install `core.hooksPath` or a `!`-shell alias, turning an allowed verb like
// `git log` into arbitrary shell the verb scan cannot see; covers `~/.gitconfig` and the XDG
// `git/config` form wherever they live.
function isGitConfigPath(path: string): boolean {
	return /(^|\/)(\.gitconfig|git\/config)$/i.test(path.replace(/\\/g, "/"));
}

// Extend the suffix list as new stacks appear (mirroring the lazy-skills rule);
// it currently covers the Go, JS/TS, Python, Ruby, and Zig test conventions.
function isTestPath(path: string): boolean {
	return (
		/(^|\/)(tests?|__tests__)\//i.test(path) ||
		/(_test\.go|\.test\.[jt]sx?|\.spec\.[jt]sx?|test_[^/]*\.py|[^/]*_test\.(py|rb|zig))$/i.test(
			path,
		)
	);
}

function deletedPaths(patchText: string): string[] {
	return [...patchText.matchAll(/\*\*\* Delete File:\s*(.+)/gi)].map((m) =>
		m[1].trim(),
	);
}

function isBashScript(path: string, content: string): boolean {
	return (
		/\.(sh|bash)$/i.test(path) ||
		/^#!\s*\/usr\/bin\/env\s+(bash|sh)\b|^#!\s*\/bin\/(ba)?sh\b/m.test(content)
	);
}

// The defensive set must be the first statement: shebang, blank lines, and comment
// headers of any length may precede it, but no code may run before it. A fixed line
// window was tried first and rejected long rationale headers that are otherwise
// harmless. Returns null when compliant, otherwise the diagnosis naming the line to
// fix so the rejection text alone is enough to correct the script.
function bashHeaderProblem(content: string): string | null {
	const lines = content.split("\n");
	const requiredLine = "set -o errexit -o nounset -o noglob -o pipefail";
	const isDefensiveSet = (line: string): boolean =>
		/^\s*set\s/.test(line) &&
		["errexit", "nounset", "noglob", "pipefail"].every((flag) =>
			line.includes(`-o ${flag}`),
		);

	const setIndex = lines.findIndex(isDefensiveSet);
	for (let index = 0; index < lines.length; index++) {
		const line = lines[index];
		const trimmed = line.trim();
		// Shebang, blank lines, and comments are allowed before the set.
		if (trimmed === "" || trimmed.startsWith("#")) {
			continue;
		}
		if (isDefensiveSet(line)) {
			return null;
		}
		return setIndex === -1
			? `the first statement is line ${index + 1} ('${trimmed.slice(0, 40)}'), but '${requiredLine}' appears nowhere; add it above line ${index + 1}, directly after the shebang and any comment header`
			: `the first statement is line ${index + 1} ('${trimmed.slice(0, 40)}'), but the defensive 'set' is at line ${setIndex + 1}; move it above line ${index + 1}`;
	}
	// Comment-only file with no statements: require the set anyway so adding code
	// later cannot slip past it.
	return setIndex === -1
		? `no '${requiredLine}' found; add it after the shebang as the first statement`
		: null;
}

function isGoMod(path: string): boolean {
	return /(^|\/)go\.mod$/i.test(path);
}

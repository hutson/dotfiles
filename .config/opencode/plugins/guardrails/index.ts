import type { Plugin } from "@opencode/plugin"

const plugin = {
	id: "guardrails",
	async setup(ctx) {
		// Permission layer: a clean `deny` with a reason. The hook runs for allow/ask
		// decisions, so it holds even when an agent's broad `allow` would otherwise win.
		await ctx.permission.hook("evaluate", (event) => {
			// Never commit, push, or stage: those are human-only actions. `rm` and `mv`
			// are included because they also stage changes. Global flags may sit
			// between `git` and the subcommand (`git -C <path> commit`), so flag tokens
			// are skipped, along with the value of the path-taking flags (`-C`,
			// `--git-dir`, `--work-tree`, `--namespace`). Skipping arbitrary
			// flag-and-value pairs instead would false-positive on read-only commands
			// whose own flags take values (for example `git log --grep commit`).
			const gitWrite = /^\s*git\s+(-\S+\s+|(-C|--git-dir|--work-tree|--namespace)\s+\S+\s+)*(commit|push|add|rm|mv)\b/
			if (event.action === "shell" && event.resources.some((r) => gitWrite.test(r))) {
				event.effect = "deny"
				event.message = "Committing, pushing, and staging are human-only (guardrails)."
				return
			}

			if (event.action === "edit" && event.resources.some(isNonLowercaseReadme)) {
				event.effect = "deny"
				event.message = "Name readme files in lowercase (readme.md)."
			}
		})

		await ctx.tool.hook("execute.before", (event) => {
			if (event.tool !== "write" && event.tool !== "edit" && event.tool !== "patch") return
			const input = (event.input ?? {}) as { path?: string; content?: string; patchText?: string }
			const patchText = input.patchText ?? ""
			const path = input.path ?? ""
			const content = input.content ?? ""

			// Never delete or blank a test file: the code must satisfy the tests, not
			// the reverse. (Weakening or gutting a test, which these checks cannot
			// catch, is graded by `test-design` at step 5 and on demand, on a tripwire
			// fire or a worker signal.)
			if (/\*\*\* Delete File:/i.test(patchText) && deletedPaths(patchText).some(isTestPath)) {
				throw new Error("Deleting test files is not allowed (guardrails).")
			}
			if (event.tool === "write" && isTestPath(path) && content.trim() === "") {
				throw new Error("Blanking a test file is not allowed (guardrails).")
			}

			// Full-content checks run on `write`, where the complete file lands.
			if (event.tool !== "write") return

			// Bash scripts must opt into safe shell behavior up front.
			if (isBashScript(path, content) && !hasDefensiveSet(content)) {
				throw new Error("Bash scripts must start with: set -o errexit -o nounset -o noglob -o pipefail (guardrails).")
			}

			// go.mod must carry both a `go` and a `toolchain` directive. This checks
			// structure only and holds no version number, so it cannot drift.
			if (isGoMod(path) && !hasGoAndToolchain(content)) {
				throw new Error("go.mod must include both a `go` and a `toolchain` directive (guardrails).")
			}
		})
	},
} satisfies Plugin.Plugin

export default plugin

function isNonLowercaseReadme(path: string): boolean {
	const base = path.split("/").pop() ?? ""
	return /^readme(\.[a-z0-9]+)?$/i.test(base) && base !== base.toLowerCase()
}

// Extend the suffix list as new stacks appear (mirroring the lazy-skills rule);
// it currently covers the Go, JS/TS, Python, Ruby, and Zig test conventions.
function isTestPath(path: string): boolean {
	return (
		/(^|\/)(tests?|__tests__)\//i.test(path) ||
		/(_test\.go|\.test\.[jt]sx?|\.spec\.[jt]sx?|test_[^/]*\.py|[^/]*_test\.(py|rb|zig))$/i.test(path)
	)
}

function deletedPaths(patchText: string): string[] {
	return [...patchText.matchAll(/\*\*\* Delete File:\s*(.+)/gi)].map((m) => m[1].trim())
}

function isBashScript(path: string, content: string): boolean {
	return (
		/\.(sh|bash)$/i.test(path) ||
		/^#!\s*\/usr\/bin\/env\s+(bash|sh)\b|^#!\s*\/bin\/(ba)?sh\b/m.test(content)
	)
}

function hasDefensiveSet(content: string): boolean {
	const head = content.split("\n").slice(0, 20).join("\n")
	return ["errexit", "nounset", "noglob", "pipefail"].every((flag) => head.includes(`-o ${flag}`))
}

function isGoMod(path: string): boolean {
	return /(^|\/)go\.mod$/i.test(path)
}

function hasGoAndToolchain(content: string): boolean {
	return /^\s*go\s+\S/m.test(content) && /^\s*toolchain\s+\S/m.test(content)
}

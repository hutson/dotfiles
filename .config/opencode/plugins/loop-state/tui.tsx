import type { Dirent } from "node:fs";
import { readdir, readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { basename, join } from "node:path";
import { Plugin } from "@opencode/plugin/tui";
// TODO: Specify third-party dependency following OpenCode's guidance (https://opencode.ai/docs/plugins/#dependencies), and not depend on the version of `solid-js` embedded in the OpenCode TUI bundle.
import { createSignal } from "solid-js";

const progressDirectory = join(homedir(), ".opencode", "progress");
const pollIntervalMs = 2_000;
const eventRefreshThrottleMs = 500;
const defaultRoundCap = 4;
const labelFieldWidth = 15;
const ruleWidth = 33;
// Documented shapes for the two agent-written strings the widget renders:
// vocabulary ids are lowercase with hyphens; slugs carry underscores too
// (`goal-file.md`: `^[A-Za-z0-9_-]+$`). Anything else is never shown raw.
const stateValuePattern = /^[a-z0-9-]{1,40}$/;
const slugPattern = /^[A-Za-z0-9_-]{1,80}$/;

// The `State:` node vocabulary lives in `skills/loop/references/goal-file.md`
// and the phase sequence in `skills/loop/SKILL.md`; this table is the display
// mirror of both, so a phase change is a deliberate three-file edit, never a
// guess at runtime. Gate lines are named by their grader's agent name (no
// `qa`/`docs` shorthand) because the human asked to read "what is running" and
// "what kind of agent" from the same line: the `●` badge and the agent name sit
// together. `supervisor` owns three lines (it is phases 0, 1, and the report)
// and never takes a badge of its own: the `▶` current marker already says the
// supervisor is working, and marking `● supervisor` would flicker on every
// token it streams between dispatches.
interface LoopNode {
	stateId: string;
	phase: number;
	label: string;
	agent: string;
	gateIndex?: number;
}

const loopNodes: LoopNode[] = [
	{ stateId: "clarify", phase: 0, label: "0 clarify", agent: "supervisor" },
	{ stateId: "plan", phase: 1, label: "1 plan", agent: "supervisor" },
	{ stateId: "design", phase: 2, label: "2 design", agent: "architect" },
	{
		stateId: "secure-design",
		phase: 3,
		label: "3 secure design",
		agent: "security",
	},
	{
		stateId: "write-tests",
		phase: 4,
		label: "4 write tests",
		agent: "developer",
	},
	{
		stateId: "review-tests",
		phase: 5,
		label: "5 review tests",
		agent: "test-design",
	},
	{ stateId: "implement", phase: 6, label: "6 implement", agent: "developer" },
	{
		stateId: "grade-qa",
		phase: 7,
		label: "7 grade",
		agent: "quality-assurance",
		gateIndex: 0,
	},
	{
		stateId: "grade-security",
		phase: 7,
		label: "7 grade",
		agent: "security",
		gateIndex: 1,
	},
	{
		stateId: "grade-docs",
		phase: 7,
		label: "7 grade",
		agent: "documentation",
		gateIndex: 2,
	},
	{ stateId: "report", phase: 8, label: "8 report", agent: "supervisor" },
];

// The gate-agent order derives from the node table (entries carrying a
// `gateIndex`), so the gate vocabulary has exactly one in-file source: a
// duplicated list could be edited on one side only and silently mislabel
// every gate mark, with nothing to detect it.
const gradeGateAgents: string[] = [];
for (const node of loopNodes) {
	if (node.gateIndex !== undefined) {
		gradeGateAgents[node.gateIndex] = node.agent;
	}
}
const supervisorAgent = "supervisor";

type GateMark = "" | "PASS" | "FAIL";

interface LoopSnapshot {
	slug: string;
	stateId: string | undefined;
	rawState: string | undefined;
	rounds: number;
	roundCap: number;
	gateMarks: GateMark[];
	tripwireFail: boolean;
	ambiguity: string[] | undefined;
}

interface GoalCandidate {
	name: string;
	slug: string;
	text: string;
	stamp: string | undefined;
}

// A missing, unparseable, or future-dated stamp never ranks, mirroring the
// `/resume` rule; ISO dates compare correctly as strings, so no parsing is
// needed once the shape is enforced.
function parseUpdatedStamp(text: string, today: string): string | undefined {
	const stamp = text.match(/^\s*-\s*Updated:\s*(\d{4}-\d{2}-\d{2})/m)?.[1];
	if (!stamp || stamp > today) {
		return undefined;
	}
	return stamp;
}

function parseRawState(text: string): string | undefined {
	const raw = text.match(/^\s*-\s*State:\s*(\S+)/m)?.[1];
	if (raw === undefined) {
		return undefined;
	}
	// The value is agent-written text destined for the terminal: one that is
	// outside the documented shape (an injected escape sequence, an absurd
	// length) renders as `<invalid>` rather than as raw bytes. A clean but
	// unknown id still shows verbatim, because the widget must display what
	// the supervisor actually wrote before deciding it is unknown.
	return stateValuePattern.test(raw) ? raw : "<invalid>";
}

// Anchored to the header's `- Stop rule:` line: prose elsewhere in the file
// that happens to contain "max 99 rounds" must not drive the cap displayed.
function parseRoundCap(text: string): number {
	const cap = Number(
		text.match(/^\s*-\s*Stop rule:[^\n]*max (\d+) rounds/i)?.[1],
	);
	return Number.isFinite(cap) && cap > 0 ? cap : defaultRoundCap;
}

// Dash-anchored like `parseGateMarks`: only `- Round <n>:` status lines count
// (including the open line of a traversal still in flight), so prose that
// merely mentions "Round 9:" never moves the counter.
function parseRounds(text: string): number {
	let rounds = 0;
	for (const match of text.matchAll(/-\s*Round (\d+):/g)) {
		rounds = Math.max(rounds, Number(match[1]));
	}
	return rounds;
}

// The newest `Round <n>:` line with a completed outcome is authoritative for
// the gate marks: gates before the named failed gate passed, that gate failed,
// and gates after it never ran in that traversal. `chain PASS` marks all three
// gates. A line written at chain entry (arrow still open) counts toward
// `parseRounds` but is skipped here, so an in-flight traversal shows its round
// number while the marks keep reporting the last completed one. The round line
// cannot distinguish a quality-assurance suite FAIL from a `test-immutability`
// FAIL, and the two route differently (back to 6 versus on-demand test-design),
// so the tripwire verdict re-routes the qa mark to node 5.
function parseGateMarks(text: string): {
	marks: GateMark[];
	tripwireFail: boolean;
} {
	const marks: GateMark[] = ["", "", ""];
	let latestRound = 0;
	let outcome = "";
	for (const match of text.matchAll(/-\s*Round (\d+):\s*([^\n]*)/g)) {
		const round = Number(match[1]);
		const afterArrow = match[2]?.split(/->|→/)[1]?.split("|")[0]?.trim();
		if (afterArrow && round >= latestRound) {
			latestRound = round;
			outcome = afterArrow;
		}
	}
	if (latestRound > 0) {
		if (/chain\s+PASS/i.test(outcome)) {
			marks[0] = "PASS";
			marks[1] = "PASS";
			marks[2] = "PASS";
		} else {
			const failedGate = gradeGateAgents.findIndex((agent) =>
				outcome.toLowerCase().includes(agent),
			);
			if (failedGate >= 0) {
				for (let index = 0; index < failedGate; index += 1) {
					marks[index] = "PASS";
				}
				marks[failedGate] = "FAIL";
			}
		}
	}
	let tripwireFail = false;
	for (const match of text.matchAll(/(PASS|FAIL)\s+test-immutability/g)) {
		tripwireFail = match[1] === "FAIL";
	}
	return { marks, tripwireFail };
}

function buildSnapshot(slug: string, text: string): LoopSnapshot {
	const rawState = parseRawState(text);
	const knownState =
		rawState !== undefined &&
		loopNodes.some((node) => node.stateId === rawState);
	const gates = parseGateMarks(text);
	return {
		slug,
		stateId: knownState ? rawState : undefined,
		rawState,
		rounds: parseRounds(text),
		roundCap: parseRoundCap(text),
		gateMarks: gates.marks,
		tripwireFail: gates.tripwireFail,
		ambiguity: undefined,
	};
}

// A tie means two or more candidates share the strictly newest ranking stamp;
// the choice then belongs to the human, like `/resume` rule 3. A lone candidate
// is shown even when its stamp does not rank: a deliberate divergence from
// `/resume`, because a passive display cannot ask and one file can only be
// that file.
function pickStrictlyNewest(
	candidates: GoalCandidate[],
): GoalCandidate | undefined {
	let chosen: GoalCandidate | undefined;
	let newest = "";
	for (const candidate of candidates) {
		if (!candidate.stamp) {
			continue;
		}
		if (candidate.stamp > newest) {
			chosen = candidate;
			newest = candidate.stamp;
		} else if (candidate.stamp === newest) {
			chosen = undefined;
		}
	}
	return chosen;
}

async function resolveSnapshot(
	project: string,
): Promise<LoopSnapshot | undefined> {
	let entries: Dirent[];
	try {
		entries = await readdir(progressDirectory, { withFileTypes: true });
	} catch {
		// No progress directory means no loop to show.
		return undefined;
	}
	// `/resume` ranks against the human's calendar date, so the future-dated
	// check compares against local today: an `toISOString()` slice returns the
	// UTC date, which in timezones ahead of UTC would make an evening
	// `Updated:` stamp look future-dated and never rank.
	const now = new Date();
	const month = String(now.getMonth() + 1).padStart(2, "0");
	const day = String(now.getDate()).padStart(2, "0");
	const today = `${now.getFullYear()}-${month}-${day}`;
	const parsed: GoalCandidate[] = [];
	for (const entry of entries) {
		// Goal files are `<project>-<slug>.md`. Snapshot directories
		// (`*-baseline/`) are excluded by the file filter; `loop-improvements.md`
		// needs an explicit exclusion because a project named `loop` would match
		// the prefix rule. A slug outside `goal-file.md`'s documented charset is
		// not a valid goal file: the slug is agent-chosen filename text the
		// widget renders, so it never reaches the terminal unvalidated.
		if (
			!entry.isFile() ||
			entry.name === "loop-improvements.md" ||
			!entry.name.startsWith(`${project}-`) ||
			!entry.name.endsWith(".md")
		) {
			continue;
		}
		const slug = entry.name.slice(project.length + 1, -".md".length);
		if (!slugPattern.test(slug)) {
			continue;
		}
		try {
			const text = await readFile(join(progressDirectory, entry.name), "utf8");
			parsed.push({
				name: entry.name,
				slug,
				text,
				stamp: parseUpdatedStamp(text, today),
			});
		} catch {
			// An unreadable candidate is skipped rather than drawn partially.
		}
	}
	if (parsed.length === 0) {
		return undefined;
	}
	if (parsed.length === 1 && parsed[0]) {
		return buildSnapshot(parsed[0].slug, parsed[0].text);
	}
	const chosen = pickStrictlyNewest(parsed);
	if (chosen) {
		return buildSnapshot(chosen.slug, chosen.text);
	}
	return {
		slug: "",
		stateId: undefined,
		rawState: undefined,
		rounds: 0,
		roundCap: defaultRoundCap,
		gateMarks: ["", "", ""],
		tripwireFail: false,
		ambiguity: parsed.map((candidate) => candidate.slug).sort(),
	};
}

interface LoopSessionCache {
	root: (sessionID: string) => string | undefined;
	family: (sessionID: string) => string[] | undefined;
	get: (sessionID: string) => { agent?: string } | undefined;
	status: (sessionID: string) => unknown;
}

// `session.status()` mirrors the server's active-session report, which lists a
// session only while it is running. Badges fail closed: only a recognized
// non-idle state (the documented `{ type: "running" }` shape, or an equivalent
// bare string) draws a `●`, so a reshaped API can never light a badge wrongly.
function isRunning(status: unknown): boolean {
	if (!status) {
		return false;
	}
	if (typeof status === "string") {
		return status !== "" && status !== "idle";
	}
	if (typeof status === "object") {
		const type = (status as { type?: unknown }).type;
		return typeof type === "string" && type !== "idle";
	}
	return false;
}

function collectRunningAgents(
	sessions: LoopSessionCache,
	sessionID: string | undefined,
): Map<string, number> {
	const counts = new Map<string, number>();
	if (!sessionID) {
		return counts;
	}
	try {
		const root = sessions.root(sessionID) ?? sessionID;
		const ids = new Set<string>([
			sessionID,
			root,
			...(sessions.family(sessionID) ?? []),
		]);
		for (const id of ids) {
			if (!isRunning(sessions.status(id))) {
				continue;
			}
			const agent = sessions.get(id)?.agent;
			if (!agent) {
				continue;
			}
			counts.set(agent, (counts.get(agent) ?? 0) + 1);
		}
	} catch {
		// A renamed or missing data API must not take the widget down; the
		// goal-file state still renders without live badges.
	}
	counts.delete(supervisorAgent);
	return counts;
}

type LineKind =
	| "muted"
	| "faint"
	| "current"
	| "done"
	| "badge"
	| "pass"
	| "fail";

interface DiagramLine {
	text: string;
	kind: LineKind;
}

function badgeText(count: number): string {
	return count > 1 ? `●x${count}` : "●";
}

function gateMarkText(
	mark: GateMark,
	gateIndex: number,
	tripwireFail: boolean,
): string {
	if (mark === "PASS") {
		return "PASS";
	}
	if (mark === "FAIL") {
		return gateIndex === 0 && tripwireFail ? "↺5" : "↺6";
	}
	return "";
}

function ambiguityLines(slugs: string[]): DiagramLine[] {
	return [
		{ text: `loops: ${slugs.join(", ")}`, kind: "muted" },
		{ text: "─".repeat(ruleWidth), kind: "muted" },
		{ text: "no unique newest Updated:", kind: "faint" },
		{ text: "pick one: /resume <slug>", kind: "faint" },
	];
}

// OpenTUI text elements are single-colored, so a line takes the color of its
// strongest signal: a running or failing worker recolors its whole line, which
// reads as the line being "alive" rather than one character glowing in place.
function buildDiagramLines(
	snapshot: LoopSnapshot,
	running: Map<string, number>,
): DiagramLine[] {
	if (snapshot.ambiguity) {
		return ambiguityLines(snapshot.ambiguity);
	}
	const currentPhase = snapshot.stateId
		? loopNodes.find((node) => node.stateId === snapshot.stateId)?.phase
		: undefined;
	const agentOccurrences = new Map<string, number>();
	for (const node of loopNodes) {
		agentOccurrences.set(
			node.agent,
			(agentOccurrences.get(node.agent) ?? 0) + 1,
		);
	}
	// `explore` and any other dispatched agent outside the vocabulary has no
	// line to hold a badge, so it marks the current node line instead: every
	// dispatched worker outside the vocabulary still shows, while the
	// supervisor's own session is deliberately excluded from badge counting.
	let unmatched = 0;
	for (const [agent, count] of running) {
		if (!agentOccurrences.has(agent)) {
			unmatched += count;
		}
	}

	const lines: DiagramLine[] = [];
	lines.push({ text: `loop: ${snapshot.slug}`, kind: "muted" });
	if (snapshot.stateId === undefined) {
		// A value outside the vocabulary is shown as parsed (`<invalid>` if its
		// text is outside the documented shape), and a missing one as
		// `not recorded`; the graph stays unhighlighted, because the widget
		// never guesses the loop's position.
		lines.push({
			text: `state: ${snapshot.rawState ?? "not recorded"}`,
			kind: snapshot.rawState ? "fail" : "muted",
		});
	}
	lines.push({ text: "─".repeat(ruleWidth), kind: "muted" });

	const phases: number[] = [];
	for (const node of loopNodes) {
		if (!phases.includes(node.phase)) {
			phases.push(node.phase);
		}
	}
	for (const [phaseIndex, phase] of phases.entries()) {
		if (phaseIndex > 0) {
			lines.push({ text: "   │", kind: "muted" });
		}
		const primary = loopNodes.find((node) => node.phase === phase);
		if (!primary) {
			continue;
		}
		const isCurrent = currentPhase === phase;
		const isDone = currentPhase !== undefined && phase < currentPhase;
		// Shared agents (security at 3 and at its gate, developer at 4 and 6)
		// badge only on the current line; the `State:` node disambiguates which
		// agent instance is in flight. Unique agents (architect, test-design)
		// badge whenever running, which is how an on-demand test-design review
		// shows up while the current phase is 6 or 7. The `7 grade` parent never
		// badges its own gate agents: the gate lines below it already carry them,
		// and the parent's slot shows the round counter instead.
		const isUniqueAgent = (agentOccurrences.get(primary.agent) ?? 1) === 1;
		const ownBadge =
			phase !== 7 &&
			primary.agent !== supervisorAgent &&
			(isCurrent || isUniqueAgent)
				? (running.get(primary.agent) ?? 0)
				: 0;
		const unmatchedBadge = isCurrent ? unmatched : 0;
		const badge = ownBadge + unmatchedBadge;
		let marker = "";
		let kind: LineKind = "faint";
		if (badge > 0) {
			marker = badgeText(badge);
			kind = "badge";
		} else if (isCurrent) {
			kind = "current";
		} else if (isDone) {
			marker = "✓";
			kind = "done";
		}
		const agentField =
			phase === 7
				? snapshot.rounds > 0
					? `(round ${snapshot.rounds} of ${snapshot.roundCap})`
					: ""
				: primary.agent;
		const body = `${primary.label.padEnd(labelFieldWidth)}  ${agentField}`;
		lines.push({
			text: `${isCurrent ? "▶ " : "  "}${body}${marker ? ` ${marker}` : ""}`.trimEnd(),
			kind,
		});

		if (phase !== 7) {
			continue;
		}
		for (const [gateIndex, agent] of gradeGateAgents.entries()) {
			const gateState = loopNodes.find((node) => node.gateIndex === gateIndex);
			const gateCurrent =
				snapshot.stateId !== undefined &&
				snapshot.stateId === gateState?.stateId;
			const gateBadge =
				(agentOccurrences.get(agent) ?? 1) === 1 || gateCurrent
					? (running.get(agent) ?? 0)
					: 0;
			const mark = gateMarkText(
				snapshot.gateMarks[gateIndex] ?? "",
				gateIndex,
				snapshot.tripwireFail,
			);
			let gateMarker = "";
			let gateKind: LineKind = "faint";
			if (gateBadge > 0) {
				gateMarker = badgeText(gateBadge);
				gateKind = "badge";
			} else if (mark !== "") {
				gateMarker = mark;
				gateKind = mark === "PASS" ? "pass" : "fail";
			}
			const branch = gateIndex < gradeGateAgents.length - 1 ? "├" : "└";
			lines.push({
				text: `   │  ${branch} ${agent.padEnd(18)}${gateMarker}`.trimEnd(),
				kind: gateKind,
			});
		}
	}

	lines.push({ text: " ", kind: "faint" });
	lines.push({ text: "  ▶ current node", kind: "current" });
	lines.push({ text: "  ✓ done", kind: "done" });
	lines.push({ text: "  ● running (●x2 = two at once)", kind: "badge" });
	lines.push({ text: "  PASS gate passed", kind: "pass" });
	lines.push({ text: "  ↺n gate failed, back to node n", kind: "fail" });
	lines.push({ text: " ", kind: "faint" });
	lines.push({ text: "  round = one full qa → security", kind: "faint" });
	lines.push({ text: "  → documentation pass; the grade", kind: "faint" });
	lines.push({
		text: `  loop stops after ${snapshot.roundCap}.`,
		kind: "faint",
	});
	lines.push({ text: " ", kind: "faint" });
	lines.push({ text: "  test-design (5) also re-runs", kind: "faint" });
	lines.push({ text: "  mid-loop only when a test-change", kind: "faint" });
	lines.push({ text: "  tripwire fires or a worker", kind: "faint" });
	lines.push({ text: "  reports a bad test.", kind: "faint" });
	return lines;
}

function readColor(node: unknown, path: string[]): string | undefined {
	let current = node;
	for (const key of path) {
		if (typeof current !== "object" || current === null) {
			return undefined;
		}
		current = (current as Record<string, unknown>)[key];
	}
	if (typeof current === "string") {
		return current;
	}
	if (typeof current === "object" && current !== null) {
		const base = (current as Record<string, unknown>).base;
		if (typeof base === "string") {
			return base;
		}
	}
	return undefined;
}

function colorForKind(theme: unknown, kind: LineKind): string | undefined {
	const paths: Record<LineKind, string[][]> = {
		current: [["text", "base"]],
		done: [["text", "muted"]],
		faint: [
			["text", "faint"],
			["text", "muted"],
		],
		muted: [["text", "muted"]],
		badge: [
			["text", "feedback", "warning"],
			["text", "feedback", "success"],
			["text", "base"],
		],
		pass: [
			["text", "feedback", "success"],
			["text", "feedback", "info"],
			["text", "base"],
		],
		fail: [
			["text", "feedback", "error"],
			["text", "feedback", "warning"],
			["text", "base"],
		],
	};
	for (const path of paths[kind]) {
		const color = readColor(theme, path);
		if (color) {
			return color;
		}
	}
	return undefined;
}

export default Plugin.define({
	id: "loop-state",
	setup(context) {
		const [snapshot, setSnapshot] = createSignal<LoopSnapshot | undefined>(
			undefined,
		);

		const refresh = async () => {
			const location = context.location ?? context.data.location.default();
			const directory = location?.directory;
			if (!directory) {
				setSnapshot(undefined);
				return;
			}
			try {
				setSnapshot(await resolveSnapshot(basename(directory)));
			} catch {
				// A transient read failure keeps the last rendered state rather
				// than flashing the widget off mid-poll.
			}
		};

		void refresh();
		const timer = setInterval(() => void refresh(), pollIntervalMs);

		// Events fire far more often than the display needs; the throttle bounds
		// goal-file reads to two per second regardless of session chatter.
		let lastEventRefresh = 0;
		const stopEvents = context.data.listen(() => {
			const now = Date.now();
			if (now - lastEventRefresh < eventRefreshThrottleMs) {
				return;
			}
			lastEventRefresh = now;
			void refresh();
		});

		const unregister = context.ui.slot({
			append: "sidebar.content",
			render: (props: { sessionID?: string }) => {
				const shown = snapshot();
				if (!shown) {
					return null;
				}
				// Badges read the session cache inside the render pass, so every
				// redraw shows current session state; the 2s poll is the
				// guaranteed refresh whether or not these reads are tracked.
				const running = shown.ambiguity
					? new Map<string, number>()
					: collectRunningAgents(context.data.session, props?.sessionID);
				const lines = buildDiagramLines(shown, running);
				return (
					<box>
						{lines.map((line) => (
							<text fg={colorForKind(context.theme, line.kind)}>
								{line.text}
							</text>
						))}
					</box>
				);
			},
		});

		return () => {
			clearInterval(timer);
			stopEvents();
			unregister();
		};
	},
});

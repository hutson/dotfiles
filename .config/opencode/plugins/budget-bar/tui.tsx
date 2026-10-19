import { Plugin } from "@opencode/plugin/tui";
import { createSignal } from "solid-js";

// OpenCode Go reports its rolling, weekly, and monthly plan windows from this
// endpoint. It is undocumented: the published Console API only exposes member
// budgets, which exclude in-plan Go usage. The published docs only say "track
// your current usage in the console". Keep the URL in one constant so a path
// change is a single edit.
const usageUrl = "https://opencode.ai/zen/go/v1/usage";
// A Console service account key (oc_sk_...) with All permission. The key
// carries All because the Console offers nothing narrower for usage reads
// (human direction 2026-10-18), so the broad grant is a documented necessity,
// not a default. The key is prompted once into durable plugin storage so the
// secret never lands in cli.json or the dotfiles repo. The trade-off is
// plaintext at rest in the TUI's plugin state file, accepted because an
// untracked local file is a smaller leak surface than a committed config or a
// process environment that child tools inherit.
const serviceKeyStoreKey = "service-key";
const refreshMs = 60_000;
const fetchTimeoutMs = 10_000;
// Consecutive auth rejections needed before the stored key is purged, so one
// transient 401/403 cannot destroy a valid key.
const authRejectionsBeforePurge = 2;

// Short labels for the footer row; "rolling" is the 5-hour allowance, matching
// how the Go plan documents its limits (5-hour, weekly, monthly).
const windowLabels: [string, string][] = [
	["rolling", "5h"],
	["weekly", "wk"],
	["monthly", "mo"],
];

interface ServiceKeyRecord {
	serviceKey: string;
}

interface BudgetWindow {
	label: string;
	status: string;
	percent: number;
	resetsAt: Date;
}

interface UsageWindowJson {
	status?: unknown;
	percent?: unknown;
	resetsAt?: unknown;
}

function parseBudgetWindows(body: unknown): BudgetWindow[] | undefined {
	const usage = (body as { usage?: unknown } | null)?.usage;
	if (typeof usage !== "object" || usage === null) {
		return undefined;
	}
	const windows: BudgetWindow[] = [];
	for (const [key, label] of windowLabels) {
		const window = parseWindow(label, (usage as Record<string, unknown>)[key]);
		if (!window) {
			return undefined;
		}
		windows.push(window);
	}
	return windows;
}

function parseWindow(label: string, value: unknown): BudgetWindow | undefined {
	if (typeof value !== "object" || value === null) {
		return undefined;
	}
	const { status, percent, resetsAt } = value as UsageWindowJson;
	if (typeof status !== "string") {
		return undefined;
	}
	if (typeof percent !== "number" || !Number.isFinite(percent) || percent < 0) {
		return undefined;
	}
	if (typeof resetsAt !== "string") {
		return undefined;
	}
	const date = new Date(resetsAt);
	if (Number.isNaN(date.getTime())) {
		return undefined;
	}
	return { label, status, percent, resetsAt: date };
}

// Days for a window longer than a day out, hours (or plain minutes) inside a
// day. The footer row is narrow, so a precise countdown would read as noise.
// The resetsAt timestamps arrive from the server, so window boundaries are
// displayed as given and never recomputed (the monthly window is billing-cycle
// anchored, not calendar anchored).
function formatTimeUntil(resetsAt: Date, now: Date): string {
	const minutes = Math.max(
		0,
		Math.floor((resetsAt.getTime() - now.getTime()) / 60_000),
	);
	const days = Math.floor(minutes / 1440);
	if (days >= 1) {
		return `${days}d${Math.floor((minutes % 1440) / 60)}h`;
	}
	const hours = Math.floor(minutes / 60);
	if (hours >= 1) {
		return `${hours}h${minutes % 60}m`;
	}
	return `${minutes}m`;
}

function formatWindows(windows: BudgetWindow[], now: Date): string {
	const parts = windows.map(
		(window) =>
			`${window.label} ${Math.round(window.percent)}% (${formatTimeUntil(window.resetsAt, now)})`,
	);
	return parts.join(" ");
}

// TODO: Warn when the budget is burning too fast for the time left in the
// window, e.g. 69% consumed with only 30% of the week elapsed means the plan
// cuts off days early. The usage endpoint returns only current percent and
// resetsAt, so a pace check needs a previous snapshot kept between fetches
// (durable plugin storage, or a memory signal that survives per-location
// reloads) to compare spend growth against elapsed time.
//
// TODO: parseBudgetWindows and formatTimeUntil are the pure, extractable seam
// and have no automated tests. The validation environment runs only biome (no
// type checking) and has no JavaScript runtime, so once one exists
// `node --test` with `node:assert` is the standard offline runner. Cases:
// minute/hour/day boundaries in formatTimeUntil, an already-past resetsAt, and
// malformed status, percent, and resetsAt shapes in parseBudgetWindows. Cases
// for the refresh classification seam: a single 401/403 retains the stored key
// and the rendered data, two consecutive strikes purge the key and hide the
// segment, an intervening success resets the strike count, and an empty prompt
// submit purges the key.

export default Plugin.define({
	id: "budget-bar",
	setup(context) {
		const [windows, setWindows] = createSignal<BudgetWindow[] | undefined>(
			undefined,
		);

		const [serviceKeyRecord, updateServiceKeyRecord] = context.storage.store(
			serviceKeyStoreKey,
			{ initial: { serviceKey: "" } satisfies ServiceKeyRecord },
		);

		// Memory-only, unlike the stored key: a persisted strike would outlive a
		// restart and could discard a key that is valid again.
		let consecutiveAuthRejections = 0;

		const storeServiceKey = (serviceKey: string) =>
			updateServiceKeyRecord((draft) => {
				draft.serviceKey = serviceKey;
			});

		const refresh = async () => {
			// An absent key is not an auth failure, so this exit resets the strike
			// count: "consecutive" means adjacent in the refresh outcome sequence,
			// and any outcome other than a completed 401/403 clears it.
			if (!serviceKeyRecord.serviceKey) {
				consecutiveAuthRejections = 0;
				setWindows(undefined);
				return;
			}
			try {
				const response = await fetch(usageUrl, {
					headers: {
						authorization: `Bearer ${serviceKeyRecord.serviceKey}`,
						accept: "application/json",
					},
					signal: AbortSignal.timeout(fetchTimeoutMs),
				});
				if (response.status === 401 || response.status === 403) {
					consecutiveAuthRejections += 1;
					if (consecutiveAuthRejections < authRejectionsBeforePurge) {
						// First strike: the key stays and the rendered data stays, so the
						// cost of a blip is one interval of stale numbers rather than a
						// lost key the user would have to paste again.
						return;
					}
					// Second consecutive strike: the key is genuinely bad, so purge it and
					// hide. No re-prompt here; asking mid-session would interrupt whatever
					// the user is doing.
					await storeServiceKey("");
					consecutiveAuthRejections = 0;
					setWindows(undefined);
					return;
				}
				consecutiveAuthRejections = 0;
				// Every other failure exit hides the segment without surfacing response
				// details, which could echo credential or workspace information into the UI.
				if (!response.ok) {
					setWindows(undefined);
					return;
				}
				setWindows(parseBudgetWindows(await response.json()));
			} catch {
				consecutiveAuthRejections = 0;
				setWindows(undefined);
			}
		};

		// Detached on purpose: setup never awaits it, so the footer slot and the
		// refresh timer come up whether or not the user answers. A dismissed
		// prompt (by any dismissal path) is final for this launch, which is
		// why nothing re-asks automatically; the /budget-bar-key command below
		// is the only deliberate way to reopen it. The rejection handler is a
		// strict no-op because a rejection is a normal dismissal path, not a
		// failure to report, and surfacing it could echo the typed value back
		// into the UI. The prompt resolution proceeds in order:
		// a dismissal returns first; the value is trimmed once; an empty trim
		// takes the purge path; a non-empty trim without the oc_sk_ prefix is
		// rejected in silence before any storage write, because surfacing
		// validation would echo typed credential-adjacent text into the UI, the
		// same rationale as the no-echo exits above; any other trim is stored.
		const promptForServiceKey = () => {
			void context.ui.dialog
				.prompt({
					title: "OpenCode Console service account key",
					description:
						"Paste a service account key (oc_sk_...) with All permission, the only grant the Console offers for usage reads. Submit empty to clear the stored key; run /budget-bar-key to change it again.",
					placeholder: "oc_sk_...",
				})
				.then(async (submitted) => {
					if (submitted === undefined) {
						return;
					}
					const trimmedKey = submitted.trim();
					if (!trimmedKey) {
						// Submitting empty is the purge path: it clears the stored key so the
						// next launch prompts again instead of retrying a dead key forever.
						await storeServiceKey("");
						setWindows(undefined);
						return;
					}
					if (!/^oc_sk_/.test(trimmedKey)) {
						return;
					}
					await storeServiceKey(trimmedKey);
					void refresh();
				})
				.catch(() => {});
		};

		if (!serviceKeyRecord.serviceKey) {
			promptForServiceKey();
		}

		// The prompt is reachable on demand so a stored key can be rotated or
		// purged while it is still valid; a first-run-only prompt would leave no
		// way to retire a key short of letting two consecutive auth strikes
		// destroy it. Layers registered from setup need no manual disposal:
		// OpenCode removes them when the plugin is disabled, reloaded, or fails
		// setup.
		context.keymap.layer(() => ({
			commands: [
				{
					id: "budget-bar.key",
					title: "Set the Go plan usage service account key",
					palette: true,
					slash: { name: "budget-bar-key" },
					run: () => promptForServiceKey(),
				},
			],
		}));

		void refresh();
		const timer = setInterval(() => void refresh(), refreshMs);

		const unregister = context.ui.slot({
			append: "prompt.footer.status",
			render: () => {
				const shown = windows();
				if (!shown) {
					return null;
				}
				// context.theme.text.muted matches the token the built-in context and
				// cost footer text uses so the segment reads as part of the row;
				// context.theme.text.feedback.warning.base keeps its saturated color
				// so an over-budget window still stands out. The rejected
				// alternative, context.theme.text.base, renders as bright white
				// against dark backgrounds in the default theme.
				const color = shown.every((window) => window.status === "ok")
					? context.theme.text.muted
					: context.theme.text.feedback.warning.base;
				return <text fg={color}>{formatWindows(shown, new Date())}</text>;
			},
		});

		return () => {
			clearInterval(timer);
			unregister();
		};
	},
});

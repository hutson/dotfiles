#!/usr/bin/env bats

# Contract tests for the `add-study-materials` command and the `study-material-collector` agent it
# dispatches. Assertions only grep the repository files in place, so this suite stays offline,
# non-destructive, and fast, and it keeps passing unchanged after the files are committed. The
# wording is pinned on purpose: the command file is security reviewed (its provenance-confirmation
# paragraph and the agent's permission effects are the controls), so rewording, reordering, or
# silently stripping trailing whitespace must fail loudly here.

# TODO: Acceptance criteria AC5 through AC8 have no coverage in this file and cannot get any here:
# - AC5 (the command appears in the TUI picker) and AC6 (the model refuses the subagent tool even
#   though `subagent: false` and the permission denials only shape what the model may do) need
#   interactive or model-mediated behavior that no static assertion over the files can observe.
# - AC7 and AC8 (question generation from a confirmed reference list and from session context)
#   need loop-level CLI probes that drive a real model session, plus a human inspecting the
#   generated question files against the study-select.sh block format.
# Those probes need network access, a live model, and human TUI verification, while the repository
# testing rules require every test to be offline, non-interactive, and done in seconds, so the gap
# stays documented instead of tested.

bats_require_minimum_version 1.5.0

setup() {
	agent_file="${BATS_TEST_DIRNAME}/../.config/opencode/agents/study-material-collector.md"
	command_file="${BATS_TEST_DIRNAME}/../.config/opencode/commands/add-study-materials.md"
}

@test "the collector frontmatter declares hidden true once and mode primary once" {
	# Whole-line fixed matches so a rationale comment that names the flag can never count.
	run grep -cFx 'hidden: true' "${agent_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	run grep -cFx 'mode: primary' "${agent_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]
}

@test "the hidden flag sits in the frontmatter between mode and request" {
	mode_line="$(grep -nFx 'mode: primary' "${agent_file}" | cut -d: -f1)"
	hidden_line="$(grep -nFx 'hidden: true' "${agent_file}" | cut -d: -f1)"
	request_line="$(grep -nFx 'request:' "${agent_file}" | cut -d: -f1)"
	[ "${mode_line}" -lt "${hidden_line}" ]
	[ "${hidden_line}" -lt "${request_line}" ]

	# The body reuses `---` in its examples, so the second whole-line match is the closing
	# frontmatter delimiter; anything at or below it is body text, not frontmatter, and a
	# `hidden: true` or `request:` line that lands there would not configure anything.
	frontmatter_end="$(grep -nFx -- '---' "${agent_file}" | sed -n '2p' | cut -d: -f1)"
	[ "${hidden_line}" -lt "${frontmatter_end}" ]
	[ "${request_line}" -lt "${frontmatter_end}" ]
}

@test "the collector description keeps its single trailing space" {
	# The byte-identical constraint is easiest to break silently: a tool stripping the single
	# trailing space would leave every other check green, so the space is pinned directly.
	run grep -cE '^description:.*graded against\. $' "${agent_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	# Grep reports zero with exit status 1 here, so only the count carries the assertion.
	over_spaced_descriptions="$(grep -cE '^description:.*  +$' "${agent_file}" || true)"
	[ "${over_spaced_descriptions}" -eq 0 ]
}

@test "the add-study-materials command frontmatter matches the contract" {
	run grep -cFx 'description: Generate study question and answer material from the references in the argument or the session so far.' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	run grep -cFx 'agent: study-material-collector' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	run grep -cFx 'subagent: false' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	# Exactly two whole-line separators bound the frontmatter; a third would mean the body grew
	# a horizontal rule that some parsers read as a second frontmatter block.
	run grep -cFx -- '---' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 2 ]
}

@test "the command body carries exactly one \$ARGUMENTS after Note from me" {
	# Single quotes are deliberate: the marker must match as literal text and never expand, so
	# the expression-in-single-quotes rule is wrong for this command.
	# shellcheck disable=SC2016
	run grep -o '\$ARGUMENTS' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 1 ]

	# Same literal-match intent as the command above.
	# shellcheck disable=SC2016
	arguments_line="$(grep -nF -- '$ARGUMENTS' "${command_file}" | cut -d: -f1)"
	frontmatter_end="$(grep -nFx -- '---' "${command_file}" | sed -n '2p' | cut -d: -f1)"
	[ "${arguments_line}" -gt "${frontmatter_end}" ]

	# The note is the only sanctioned home for the user's references, so the one marker must sit
	# below the one note heading.
	run grep -cF 'Note from me:' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]
	note_line="$(grep -nF -- 'Note from me:' "${command_file}" | cut -d: -f1)"
	[ "${note_line}" -lt "${arguments_line}" ]
}

@test "the body names all three reference kinds and refuses to invent references" {
	# Property-level phrases rather than full sentences, so harmless rewording around them can
	# pass while the security-relevant properties stay pinned.
	run grep -cF 'Internet URLs' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	run grep -cF 'files on disk' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	run grep -cF 'context I provided directly in this conversation' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	run grep -cF 'ask me for them instead of guessing' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]
}

@test "the permission block keeps the catch-all deny and the subagent and websearch denials" {
	run grep -cFx '    - action: "*"' "${agent_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	run grep -cFx '    - action: subagent' "${agent_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	run grep -cFx '    - action: websearch' "${agent_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	run grep -cFx '      effect: deny' "${agent_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 3 ]

	# Pairing binds each rule to its own effect so counts alone cannot mask a flipped rule. The
	# denied actions have unique literals, so these pairings pin them exactly; rules sharing an
	# action literal are pinned by the resource-keyed pairings and per-action counts at the end
	# of this test.
	run grep -A 2 -Fx -- '    - action: "*"' "${agent_file}"
	[ "$status" -eq 0 ]
	[[ "${output}" == *'      effect: deny'* ]]

	run grep -A 2 -Fx -- '    - action: subagent' "${agent_file}"
	[ "$status" -eq 0 ]
	[[ "${output}" == *'      effect: deny'* ]]

	run grep -A 2 -Fx -- '    - action: websearch' "${agent_file}"
	[ "$status" -eq 0 ]
	[[ "${output}" == *'      effect: deny'* ]]

	# The last matching rule wins, so only a catch-all that precedes every reopening rule leaves
	# the later allow rules in charge; the catch-all must hold the smallest action line number.
	catch_all_line="$(grep -nFx -- '    - action: "*"' "${agent_file}" | cut -d: -f1)"
	first_action_line="$(grep -nE '^    - action:' "${agent_file}" | head -n 1 | cut -d: -f1)"
	[ "${catch_all_line}" -eq "${first_action_line}" ]

	run grep -cFx '      effect: ask' "${agent_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 4 ]

	# Same pairing for the four human-gated rules: shell, external_directory, and the two
	# .env-guarding read rules. These action literals are shared with allow rules, so this
	# pairing alone cannot tell same-action rules apart; the resource-keyed pairings and
	# per-action counts below bind those rules exactly.
	run grep -A 2 -Fx -- '    - action: shell' "${agent_file}"
	[ "$status" -eq 0 ]
	[[ "${output}" == *'      effect: ask'* ]]

	run grep -A 2 -Fx -- '    - action: external_directory' "${agent_file}"
	[ "$status" -eq 0 ]
	[[ "${output}" == *'      effect: ask'* ]]

	run grep -A 2 -Fx -- '    - action: read' "${agent_file}"
	[ "$status" -eq 0 ]
	[[ "${output}" == *'      effect: ask'* ]]

	# Each resource line below is unique, so pairing one with its own effect pins that rule; the
	# unique-resource pairings plus the per-action counts determine every shared-resource rule's
	# effect by elimination, so a swap between two same-action rules can no longer hide.
	run grep -A 2 -Fx -- '      resource: "*.env"' "${agent_file}"
	[ "$status" -eq 0 ]
	[[ "${output}" == *'      effect: ask'* ]]

	run grep -A 2 -Fx -- '      resource: "*.env.*"' "${agent_file}"
	[ "$status" -eq 0 ]
	[[ "${output}" == *'      effect: ask'* ]]

	run grep -A 2 -Fx -- '      resource: "*.env.example"' "${agent_file}"
	[ "$status" -eq 0 ]
	[[ "${output}" == *'      effect: allow'* ]]

	run grep -A 2 -Fx -- '      resource: "*/.config/opencode/scripts/study-select.sh *"' "${agent_file}"
	[ "$status" -eq 0 ]
	[[ "${output}" == *'      effect: allow'* ]]

	run grep -A 2 -Fx -- '      resource: ~/.config/opencode/skills/*' "${agent_file}"
	[ "$status" -eq 0 ]
	[[ "${output}" == *'      effect: allow'* ]]

	run grep -A 2 -Fx -- '      resource: ~/.config/opencode/scripts/*' "${agent_file}"
	[ "$status" -eq 0 ]
	[[ "${output}" == *'      effect: allow'* ]]

	run grep -cFx '    - action: shell' "${agent_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 2 ]

	run grep -cFx '    - action: external_directory' "${agent_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 3 ]

	run grep -cFx '    - action: read' "${agent_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 4 ]
}

@test "the command body pins the provenance-confirmation control" {
	run grep -cF 'Before fetching or reading anything' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	run grep -cF 'where it came from' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	run grep -cF 'wait for my explicit confirmation' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	run grep -cF 'did not appear verbatim in my note or my own messages as untrusted' "${command_file}"
	[ "$status" -eq 0 ]
	[ "${output}" -eq 1 ]

	# The listing must precede the instruction to act on it; a swapped order would have the
	# agent fetch before the user ever confirms provenance.
	before_line="$(grep -nF -- 'Before fetching or reading anything' "${command_file}" | cut -d: -f1)"
	perform_line="$(grep -nF -- 'Then perform your task on each extracted reference.' "${command_file}" | cut -d: -f1)"
	[ "${before_line}" -lt "${perform_line}" ]

	# U+2014 tripwire for both files. The character is built from its code point so this file
	# stays free of it, and grep exiting 1 at zero matches means only the count carries the
	# assertion.
	em_dash_character="$(printf '\u2014')"
	command_em_dash_count="$(grep -c "${em_dash_character}" "${command_file}" || true)"
	[ "${command_em_dash_count}" -eq 0 ]
	agent_em_dash_count="$(grep -c "${em_dash_character}" "${agent_file}" || true)"
	[ "${agent_em_dash_count}" -eq 0 ]
}

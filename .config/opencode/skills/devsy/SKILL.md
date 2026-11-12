---
name: Devsy
description: Facts about the devsy Dev Container runner (command shape, workspace lifecycle, wrapper output). Load when a brief or task runs tests or gates through `devsy ci`.
---

# Devsy

Devsy runs a command inside a Dev Container workspace: `devsy ci [flags] [workspace-path] -- <command>`, for example `devsy ci . -- bash .tools/test.sh`. The container's pinned toolchain is the authoritative environment for gates; a host-tool-version failure on content the change did not touch is an artifact of the host, not a finding.

## Workspace lifecycle

- A `devsy ci` run tears its workspace down when the run ends, so nothing persists between runs; capture anything you need into the run directory during the run.
- A first run that exits 127 with missing files is the stale-workspace signature. The supported recovery is a rebuild without cache (`devsy workspace build --no-cache`) followed by re-running the command; a `--no-cache` flag on `ci` itself does not force the rebuild. Recovery is build-only: never delete, rename, or overwrite workspace or project files to "clean up" after a failed run.

## Wrapper output

`devsy ci` wraps the entry point's output with host-side lines of its own (padded stage labels such as `[RUN]  ci:` and `[OK]   ci:`, bare `{"kind":"status",...}` JSON lines, `{"kind":"result",...}` JSON, and teardown lines after the entry point's own output). Consequences:

- The entry point's final output line is not the transcript's final line, so a final-line equality check must scope to the entry point's own section or tolerate the wrapper tail.
- Any check that parses wrapper output is endorsed against captured transcript evidence (a saved run log), never a prose rendering. The grammar beyond the shapes above is unverified; capture a real transcript before relying on anything narrower.

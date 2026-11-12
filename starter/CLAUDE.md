# Project

## Running Things

- While working: `bin/changed` formats, lints and tests the files changed
  since the last commit, and requires 100% coverage of each changed source.
  One test file: `bin/test <file>`.
- A formatting finding from the guards is fixed with `bin/format`.
- Before every commit: `bin/ci`. Judge it by its PASS / FAIL / SKIP lines;
  one FAIL fails the gate.
- Run scripts by relative path (`bin/ci`), never an absolute one. Never call
  the toolchain (bun, Biome, Ruff, RuboCop, cargo, swift) directly; call the
  `bin/` script that wraps it.
- To see a web app running, use its `bin/open`.
- Search with `bin/scan`: `refs <string>` (matches and the commits that
  added or removed them), `log <git-log-args>`, `grep <rg-args>`,
  `files <pathspec>`.
- Version changes go through `bin/dependencies`, then `bin/ci`.
- A toolchain mismatch from `bin/ci` is fixed by installing the pinned
  version, never by editing the pin to match what is installed.
- The gate (`bin/`, `tests/guards`, `tests/run`), lint configuration,
  `.claude/` and this file change only with an explicit go.

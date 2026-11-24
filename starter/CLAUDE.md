# Project

## Running Things

- While working: `bin/changed` formats, lints and tests the files changed
  since the last commit, and requires 100% coverage of each changed source.
  One test file: `bin/test <file>`.
- A formatting finding from the guards is fixed with `bin/format`.
- Before every commit: `bin/ci`. Judge it by its PASS / FAIL / SKIP lines;
  one FAIL fails the gate.
- Commit only with `bin/commit <branch> <msgfile>`, the message written to a
  file from `mktemp /tmp/flow-commit-msg.XXXXXX`. It reviews changed rules,
  runs `bin/ci`, then commits and pushes; read the JSON line it prints.
- Start work with `bin/start <branch>`, then `cd .worktrees/<branch>` and
  run every script and make every edit there. Land it from the worktree
  with `bin/complete <branch> <msgfile>`, which squashes it onto `main`
  and deletes it.
- Run scripts by relative path (`bin/ci`), never an absolute one. Never call
  the toolchain (bun, Biome, Ruff, RuboCop, cargo, swift) directly; call the
  `bin/` script that wraps it.
- To see a web app running: `bin/open <app folder>`, or `bin/open` for an
  app at the repo root.
- Search with `bin/scan`: `refs <string>` (matches and the commits that
  added or removed them), `log <git-log-args>`, `grep <rg-args>`,
  `files <pathspec>`.
- Look at the database only with `bin/query "<sql>"`, which is read-only.
- Version changes go through `bin/dependencies`, then `bin/ci`.
- A toolchain mismatch from `bin/ci` is fixed by installing the pinned
  version, never by editing the pin to match what is installed.
- An app that fails `bin/ci` on time is made faster; never edit its
  `.ci-timeout`.
- The gate (`bin/`, `tests/guards`, `tests/run`), lint configuration,
  `.claude/` and this file change only with an explicit go.

# bin-stubs

## Running Things

- `bin/ci` is this repo's gate. It runs `tests/run`, which needs node,
  uv, ruby with bundler, cargo, cargo-llvm-cov with LLVM's tools, Xcode,
  shellcheck, shfmt, markdownlint-cli2, ripgrep and jq installed.
- Iterate with `starter/tests/run` (the guard suite on this repo, seconds);
  run `bin/ci` before every commit.
- Run scripts by their relative path (`bin/ci`, `tests/run`), never an
  absolute one.
- Commits here go through `bin/commit <branch> <msgfile>`, not
  `flow-pro commit`.
- Branch names have no `/`; `bin/commit` rejects them.
- Work happens on a branch opened with `bin/start <branch>`: `cd` into
  `.worktrees/<branch>` and run every script and make every edit there,
  one `bin/commit --no-push <branch>` commit per task. It lands on `main`
  as one squash with `bin/complete <branch> <msgfile>`, run from the
  worktree.

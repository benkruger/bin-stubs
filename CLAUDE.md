# bin-stubs

## Running Things

- `bin/ci` is this repo's gate. It runs `tests/run`, which needs node,
  uv, cargo, swift, shellcheck, shfmt, markdownlint-cli2 and jq installed.
- Iterate with `starter/tests/run` (the guard suite on this repo, seconds);
  run `bin/ci` before every commit.
- Run scripts by their relative path (`bin/ci`, `tests/run`), never an
  absolute one.
- Branch names have no `/`; flow-pro rejects them.
- A branch with one commit lands on `main` by fast-forward
  (`git merge --ff-only <branch>`, then `git push`); flow-pro already gated
  that commit.

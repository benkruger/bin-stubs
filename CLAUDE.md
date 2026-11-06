# bin-stubs

## Running Things

- `bin/ci` is this repo's gate. It runs `tests/run`, which needs bun, node,
  uv, cargo and swift installed.
- Iterate with `tests/guards` (lint and shape checks, seconds); run `bin/ci`
  before every commit.
- Run scripts by their relative path (`bin/ci`, `tests/run`), never an
  absolute one.
- Branch names have no `/`; flow-pro rejects them.

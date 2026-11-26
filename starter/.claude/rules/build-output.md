# Build Output

Only source goes into git; build and coverage output stays out.

## The Rule

- `.gitignore` lists every folder in `OUTPUT_DIRS`: `node_modules/`,
  `dist/`, `build/`, `coverage/`, `.venv/`, `target/`, `.build/` and
  `.flow-states/`. `tests/guards` fails a missing `.gitignore` or one
  missing one of those lines, and a tracked or visible file under one of
  those folders or under `vendor/bundle/`, an `lcov.info` or a
  `.tsbuildinfo`.
  Trigger: any new output folder or `.gitignore` edit.
<!-- audited: 7c5c19abfab6 -->

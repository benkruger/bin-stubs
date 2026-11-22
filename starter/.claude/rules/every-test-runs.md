# Every Test Runs

Every test runs on every `bin/ci`; a test that cannot pass yet is fixed or
deleted.

## The Rule

- `bin/ci` fails while a test fails, so a test that cannot pass is fixed
  or deleted in the change that finds it failing. Trigger: a failing
  test.
- Every test runs unmarked and is expected to pass; `tests/guards` fails a
  line marking a test skipped, focused, todo or expected to fail. It scans
  every `.rs` file and each file `skip_pattern_of` classes as a test by its
  path, and fails a line that matches the pattern it picks: `SKIP_JS`
  (Vitest, Jest, node:test), `SKIP_PY` (pytest, unittest), `SKIP_RUBY`
  (Minitest, RSpec), `SKIP_RUST` (cargo test) and `SKIP_SWIFT` (XCTest,
  Swift Testing). Trigger: any new or edited test or `.rs` file.
<!-- audited: 30066420c61f -->

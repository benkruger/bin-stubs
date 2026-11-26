# Every Test Runs

Every test runs on every `bin/ci`; a test that cannot pass yet is fixed or
deleted.

## The Rule

- `bin/ci` fails while a test fails, so a test that cannot pass is fixed
  or deleted in the change that finds it failing. Trigger: a failing
  test.
- Every test runs unmarked and is expected to pass; `tests/guards` fails a
  line marking a test skipped, focused, todo or expected to fail, or
  leaving test files out of pytest's collection. It scans
  every `.rs` file and each file `skip_pattern_of` classes as a test by its
  path, and fails a line that matches the pattern it picks: `SKIP_JS`
  (Vitest, Jest, node:test, Playwright), `SKIP_PY` (pytest, unittest),
  `SKIP_RUBY` (Minitest, RSpec), `SKIP_RUST` (cargo test) and `SKIP_SWIFT`
  (XCTest, Swift Testing). In a JS test file, `js_test_calls` fails a
  `skip`, `only`, `todo` or `fails` key not set to `false` in an object
  passed to a `test`, `it`, `describe` or `suite` call, on whatever line
  it sits. It also fails any key in `PYTEST_COLLECTION`, whatever its
  value, quoting or `=` or `:` separator, under pytest's section, its
  header's quotes ignored, of a `pyproject.toml`, `pytest.toml`,
  `.pytest.toml`, `pytest.ini`, `.pytest.ini`, `tox.ini` or `setup.cfg`: a
  key that sets which directories, files, classes or functions pytest
  collects. Trigger: any new or edited test, `.rs` file or pytest config.
- Every test target runs: `tests/guards` fails a `.xcscheme` or
  `.xctestplan` line matching `TEST_SELECTION_XCODE` (a skipped testable,
  skipped or selected tests or tags, a target that is not enabled), and a
  `Cargo.toml` line `cargo_test_targets` finds: `autotests` under
  `[package]`, `test` under `[lib]`, `[[bin]]` or `[[test]]`, or `harness`
  under `[[test]]`, set to `false`. Trigger: any new or edited scheme,
  test plan or `Cargo.toml`.
<!-- audited: f6818a0a0d76 -->

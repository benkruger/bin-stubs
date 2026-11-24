# Python Standards

The Python app is held by Ruff and pytest at full strength.

## The Rule

- A source is a `.py` file under `src/` when it exists, else anywhere in
  the app, the tree coverage measures; `is_source` in
  `bin/_python/lib/sources.sh`, which `bin/test` and `bin/changed` share,
  leaves out only `tests/`, `.venv/` and a root `conftest.py`.
- Every source `<dir>/<name>.py` (or `src/<dir>/<name>.py`) other than a
  package's `__init__.py` has its twin `tests/<dir>/test_<name>.py`.
  `bin/changed` fails a changed source with no twin; `bin/ci` fails any
  source with none, and `bin/test` fails a test whose source does not
  exist.
- Every source is at 100% coverage. `bin/ci` checks every source;
  `bin/changed` checks the changed ones, and a changed test holds its source
  to the same bar. pytest runs with the app's `addopts` cleared, and
  `bin/test` fails a run with no coverage report (`full-coverage.md`).
- Ruff formats every file and lints it with its default rules and any
  the config adds through `extend-select`; `bin/lint` fails a finding, and
  `tests/guards` fails a Ruff setting other than `target-version`,
  `line-length`, `indent-width`, `src`, `format` or lint `extend-select`
  (`no-lint-exceptions.md`).
- `bin/build` compiles every module and fails on any that does not
  compile, then type-checks every Python file in the app with
  `mypy --strict` and fails on any error, or when mypy is not installed
  in the app's environment.
- `.python-version` pins Python; outside CI, `bin/ci` fails unless uv finds
  an installed Python that matches it.
- Trigger: any change to a Python `bin/` script.
<!-- audited: 8ec1a63c308b -->

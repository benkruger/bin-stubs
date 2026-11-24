# Python Standards

The Python app is held by Ruff and pytest at full strength.

## The Rule

- A source is a `.py` file under `src/` when it exists, else anywhere in
  the app, the tree coverage measures; `is_source` in `bin/_python/test`
  holds the one list of test files and `conftest.py` it leaves out.
- Every source `<dir>/<name>.py` (or `src/<dir>/<name>.py`) other than a
  package's `__init__.py` has its twin `tests/<dir>/test_<name>.py`.
  `bin/changed` fails a changed source with no twin; `bin/ci` fails any
  source with none, and `bin/test` fails a test whose source does not
  exist.
- Every source is at 100% coverage. `bin/ci` checks every source;
  `bin/changed` checks the changed ones, and a changed test holds its source
  to the same bar.
- Ruff formats every file and lints it with its default rules and any
  the config adds through `extend-select`; `bin/lint` fails a finding, and
  `tests/guards` fails a Ruff setting other than `target-version`,
  `line-length`, `indent-width`, `src`, `format` or lint `extend-select`
  (`no-lint-exceptions.md`).
- `bin/build` compiles every module and fails on any that does not
  compile.
- `.python-version` pins Python; `bin/ci` fails unless uv finds an installed
  Python that matches it.
- Trigger: any change to a Python `bin/` script.
<!-- audited: a8eda23c9cc7 -->

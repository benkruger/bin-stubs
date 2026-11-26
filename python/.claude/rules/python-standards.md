# Python Standards

The Python app is held by Ruff and pytest at full strength.

## The Rule

- A source is a `.py` file under `src/` when it exists, else anywhere in
  the app, the tree coverage measures; `is_source` in
  `bin/_python/lib/sources.sh`, which `bin/test` and `bin/changed` share,
  leaves out only `tests/`, `.venv/` and a root `conftest.py`.
- Every source `<dir>/<name>.py` (or `src/<dir>/<name>.py`) other than a
  package's `__init__.py` has its twin `tests/<dir>/test_<name>.py`.
  `bin/changed` fails a changed source with no twin; `bin/ci` fails any source
  with none, and `bin/test` fails a test (`test_<name>.py` or `<name>_test.py`
  under `tests/`) whose source does not exist, runs a named source's twin, and
  fails a named source with none; given no paths, `bin/test` also fails a file
  so named outside `tests/` that is no source.
- Every source is at 100% coverage. `bin/ci` checks every source;
  `bin/changed` checks the changed ones, and a changed test holds its source
  to the same bar. pytest runs with the app's `addopts` cleared and with
  `-W error`, so a warning fails the test that raises it, and `bin/test`
  fails a run with no coverage report (`full-coverage.md`).
- Ruff formats every file and lints it with its default rules and any
  the config adds through `extend-select`; `bin/lint` fails a finding, and
  `tests/guards` fails a Ruff setting other than `target-version`,
  `line-length`, `indent-width`, `src`, `format` or lint `extend-select`
  (`no-lint-exceptions.md`).
- `bin/build` compiles every Python file in the app that git lists,
  tracked or untracked and not ignored, and fails on any that does not
  compile, then type-checks those files with `mypy --strict` and fails on
  any error, or when mypy is not installed in the app's environment.
- `.python-version` pins Python; outside CI, `bin/ci` and
  `bin/dependencies` fail unless uv finds an installed Python that matches
  it. Every Python script runs uv with `UV_PYTHON_DOWNLOADS=never`, and
  `tests/core` fails when `bin/dependencies` or the shared `toolchain.sh`
  lets uv download a Python.
- `packages_check` fails, as `packages.md` states, when
  `uv sync --locked --offline --check` fails: `uv.lock` does not
  match `pyproject.toml` or `.venv` does not match `uv.lock`.
- Trigger: any change to a Python `bin/` script.
<!-- audited: 5a0463b4dc72 -->

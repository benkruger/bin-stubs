# Python Standards

The Python app is held by Ruff and pytest at full strength.

## The Rule

- Every source `<dir>/<name>.py` (or `src/<dir>/<name>.py`) has its twin
  `tests/<dir>/test_<name>.py`. `bin/changed` fails a changed source with no
  twin; `bin/ci` fails any source with none.
- Every source is at 100% coverage. `bin/ci` checks every source;
  `bin/changed` checks the changed ones, and a changed test holds its source
  to the same bar.
- Ruff formats every file and lints it with every rule
  (`no-lint-exceptions.md`).
- `bin/build` compiles every module.
- `.python-version` pins Python; `bin/ci` fails unless uv finds an installed
  Python that matches it.

# Python Standards

The Python app is held by Ruff and pytest at full strength.

## The Rule

- Every source `<dir>/<name>.py` (or `src/<dir>/<name>.py`) has its twin
  `tests/<dir>/test_<name>.py`. `bin/changed` and `bin/test` fail a changed
  source with no twin.
- Every changed source is at 100% coverage; a changed test holds its source
  to the same bar.
- Ruff formats every file and lints it with every rule
  (`no-lint-exceptions.md`).
- `bin/build` compiles every module.
- `.python-version` pins Python; `bin/ci` fails unless uv finds an installed
  Python that matches it.

# Test Time Limits

A suite runs on its runner's default time limit; a slow test gets faster,
and a JS or pytest limit on one test is a plain number.

## The Rule

- A suite runs on its runner's default time limit, and in JS or pytest a
  limit on a single test is a plain number. `tests/guards` fails each line
  `timeout_lines` finds: a flag, the `-o` or `--override-ini` value
  `timeout=` quoted or not, or the `PYTEST_TIMEOUT` variable, matching
  `TIMEOUT_FLAGS` anywhere in a `bin/` script,
  `package.json`, `pyproject.toml`, `pytest.toml`,
  `.pytest.toml`, `pytest.ini`, `.pytest.ini`, `tox.ini` or `setup.cfg`;
  `testTimeout`, `hookTimeout` or `teardownTimeout` in `package.json` or a
  Vitest or Jest config; a `timeout` key, quoted or not, set with `=` or
  `:`, under `[test]` in `bunfig.toml` or in pytest's section of one of
  those pytest files; `testTimeoutsEnabled`,
  `defaultTestExecutionTimeAllowance` or
  `maximumTestExecutionTimeAllowance` in an `.xctestplan`; and, in a test
  file `skip_pattern_of` classes (`every-test-runs.md`), an assignment to
  `executionTimeAllowance` in Swift, a `jest.setTimeout`, `vi.setConfig` or
  `setDefaultTimeout` call or a `timeout:` value that is not a plain
  number in JS, or an `@pytest.mark.timeout` argument that is not a
  plain number. In a JS test file, `js_test_calls` fails the third
  argument of a `test`, `it`, `describe` or `suite` call unless it is a
  plain number, a function, an object, or a lone run of word characters,
  `$` and dots after a second argument that is not a function. Trigger:
  any new or edited test, test config or `bin/` script.
- A test that times out is a failing test, fixed or deleted as
  `every-test-runs.md` states; the fix makes it faster and adds no limit
  the bullet above lists, which `tests/guards` fails. Trigger: a test
  that times out.
<!-- audited: 470e4b1efda4 -->

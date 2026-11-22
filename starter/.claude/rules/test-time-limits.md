# Test Time Limits

A suite runs on its runner's default time limit; a slow test gets faster,
and a JS or pytest limit on one test is a plain number.

## The Rule

- A suite runs on its runner's default time limit, and in JS or pytest a
  limit on a single test is a plain number. `tests/guards` fails each line
  `timeout_lines` finds: a flag matching `TIMEOUT_FLAGS` anywhere in a
  `bin/` script, `package.json`, `pyproject.toml`, `pytest.ini`, `tox.ini`
  or `setup.cfg`; `testTimeout`, `hookTimeout` or `teardownTimeout` in
  `package.json` or a Vitest or Jest config; `timeout` under `[test]` in
  `bunfig.toml` or in pytest's settings; `testTimeoutsEnabled`,
  `defaultTestExecutionTimeAllowance` or
  `maximumTestExecutionTimeAllowance` in an `.xctestplan`; and, in a test
  file `skip_pattern_of` classes (`every-test-runs.md`), an assignment to
  `executionTimeAllowance` in Swift, a `jest.setTimeout`, `vi.setConfig` or
  `setDefaultTimeout` call or a `timeout:` value that is not a plain
  number in JS, or an `@pytest.mark.timeout` argument that is not a
  plain number. Trigger: any new or edited test, test config or `bin/`
  script; the review refuses any other limit.
- A test that times out is a failing test, fixed or deleted as
  `every-test-runs.md` states; the fix makes it faster, never gives it
  more time, and the review refuses a change that does otherwise.
  Trigger: a test that times out.
<!-- audited: a7f8ea26431c -->

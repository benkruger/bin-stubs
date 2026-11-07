# Rails Standards

The Rails app is held by RuboCop, Brakeman, Zeitwerk and Minitest at full
strength.

## The Rule

- Every source `app/<path>.rb` has its twin `test/<path>_test.rb`, and every
  `lib/<path>.rb` has its twin `test/lib/<path>_test.rb`. `bin/changed` fails
  a changed source with no twin.
- `bin/test` runs the suite with `rails test`, after `db:test:prepare` when
  the app has `config/database.yml`.
- `test/test_helper.rb` starts SimpleCov with 100% line and branch coverage
  before the app loads. When `COVERAGE_DIRTY_FILES` names a file list, it
  counts only those files; `bin/changed` sets it.
- Ruby runs the suite with warnings on; a warning from the app's own code
  fails it.
- RuboCop autocorrects, then any offense left fails. Brakeman fails on any
  warning. Neither is configured off (`no-lint-exceptions.md`).
- `bin/build` eager-loads the app with Zeitwerk.

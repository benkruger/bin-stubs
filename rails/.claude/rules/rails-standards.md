# Rails Standards

The Rails app is held by RuboCop, Brakeman, Zeitwerk and Minitest at full
strength.

## The Rule

- Every source `app/<path>.rb` has its twin `test/<path>_test.rb`, and every
  `lib/<path>.rb` has its twin `test/lib/<path>_test.rb`. `bin/changed` fails
  a changed source with no twin, and `bin/test` fails a test whose source
  does not exist, outside `test/integration`, `test/system`,
  `test/support` and `test/fixtures`.
- `bin/test` runs the suite with `rails test`, after `db:test:prepare` when
  the app has `config/database.yml`.
- `test/test_helper.rb` starts SimpleCov with 100% line and branch coverage
  before the app loads. When `COVERAGE_DIRTY_FILES` names a file list, it
  counts only those files; `bin/changed` sets it.
- Ruby runs the suite with warnings on; a warning from the app's own code
  fails it.
- RuboCop runs with `--enable-pending-cops` and autocorrects, then any
  offense left fails `bin/lint`, and no cop is turned off beyond what
  `no-lint-exceptions.md` allows. Brakeman fails `bin/lint` on any warning.
- `bin/build` eager-loads the app with Zeitwerk.
- `bin/dependencies` updates gems as `packages.md` states, then fails
  on any gem `bundler-audit` flags and on any Brakeman warning.
- `.ruby-version` pins Ruby; `bin/ci` fails unless that version is active.
- `bin/qa`, outside `bin/ci`, runs `rails test:system`; a failed test, or an
  output line matching `warn` or `deprecat` in any case, fails it.
- Trigger: any change to a Rails `bin/` script or `test/test_helper.rb`.
<!-- audited: 7654109dddad -->

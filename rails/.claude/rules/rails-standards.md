# Rails Standards

The Rails app is held by RuboCop, Brakeman, Zeitwerk and Minitest at full
strength.

## The Rule

- Every source `app/<path>.rb` has its twin `test/<path>_test.rb`, and every
  `lib/<path>.rb` has its twin `test/lib/<path>_test.rb`, as
  `bin/_rails/lib/sources.sh`, which `bin/test` and `bin/changed` share,
  maps them. `bin/changed` fails a changed source with no twin; `bin/test`
  on a whole run fails any source with none; on any run it fails a test it
  checks whose source does not exist, outside `test/integration`,
  `test/system`, `test/support` and `test/fixtures`. `bin/test` runs a
  named source's twin and fails a named source with none.
- `bin/test` runs the suite with `rails test`, after `db:test:prepare` when
  the app has `config/database.yml`.
- `test/test_helper.rb` starts SimpleCov with 100% line and branch coverage
  before the app loads. `bin/test` then reads SimpleCov's resultset and
  fails any source below 100% lines or branches, or with no row: every
  `app/` and `lib/` `.rb` file on a whole run, the files the list
  `COVERAGE_DIRTY_FILES` names when `bin/changed` sets it, and the sources
  of the tests `bin/test <file>` runs.
- Ruby runs the suite with warnings on; a warning from the app's own code
  fails it.
- `bin/format` autocorrects with RuboCop under `--enable-pending-cops` and
  fixes Markdown with `markdownlint-cli2` from PATH; with `--check` it fails
  a RuboCop Layout offense or a `markdownlint-cli2` finding. `bin/lint`
  fails any RuboCop offense, any Brakeman warning and any
  `markdownlint-cli2` finding, and no cop is turned off beyond what
  `no-lint-exceptions.md` allows.
- `bin/build` eager-loads the app with Zeitwerk.
- `bin/dependencies` updates gems as `packages.md` states, then fails
  on any gem `bundler-audit` flags and on any Brakeman warning.
- `.ruby-version` pins Ruby; outside CI, `bin/ci` fails unless that version
  is active.
- `bin/qa`, outside `bin/ci`, runs `rails test:system`; a failed test, or an
  output line matching `warn` or `deprecat` in any case, fails it.
- Trigger: any change to a Rails `bin/` script or `test/test_helper.rb`.
<!-- audited: 11fe28f7eb18 -->

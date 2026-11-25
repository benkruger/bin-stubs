# Rails Standards

The Rails app is held by RuboCop, Brakeman, Zeitwerk and Minitest in full.

## The Rule

- Every source `app/<path>.rb` has its twin `test/<path>_test.rb`, and every
  `lib/<path>.rb` has its twin `test/lib/<path>_test.rb`, as
  `bin/_rails/lib/sources.sh`, which `bin/test` and `bin/changed` share,
  maps them. `bin/changed` fails a changed source with no twin. `bin/test`
  fails a source it checks with no twin and a test it checks whose source
  does not exist, outside `test/integration`, `test/system`,
  `test/support` and `test/fixtures`; it runs a named source's twin and
  fails a named source with none.
- `bin/test` runs the suite with `rails test`, after `db:test:prepare` when
  the app has `config/database.yml`.
- `test/test_helper.rb` starts SimpleCov with 100% line and branch coverage
  before the app loads. `bin/test` then reads SimpleCov's resultset and
  fails any source it checks below 100% lines or branches, or with no row:
  with `--all`, as `bin/ci` runs it, every `app/` and `lib/` `.rb` file;
  given paths, the sources of the tests they name, so a changed test holds
  its source too; given neither, the changed sources and the changed
  tests' sources. Only with `--all` does SimpleCov's own minimum, over
  every file the run loads, fail `bin/test`.
- Ruby runs the suite with warnings on; a warning from app code fails it.
- `bin/format` autocorrects with RuboCop under `--enable-pending-cops`; with
  `--check` it fails a RuboCop Layout offense. `bin/lint` fails any RuboCop
  offense and any Brakeman warning, and leaves Markdown to `tests/guards`; no
  cop is turned off beyond what `no-lint-exceptions.md` allows.
- `bin/build` eager-loads the app with Zeitwerk.
- `bin/dependencies` updates gems as `packages.md` states, then fails
  on any gem `bundler-audit` flags and on any Brakeman warning.
- `.ruby-version` pins Ruby; outside CI, `bin/ci` fails unless it is active.
- `bin/qa`, outside `bin/ci`, runs `rails test:system`; a failed test, or an
  output line matching `warn` or `deprecat` in any case, fails it, and
  SimpleCov's minimum does not. `bin/changed` hands `bin/test` a changed test
  only when `is_test` admits it, never one under `test/system`, and `rails test`
  given no path skips `test/system`: `bin/changed` runs a changed system test
  only as a changed source's twin, and `bin/test` given no path never does.
- Trigger: any change to a Rails `bin/` script or `test/test_helper.rb`.
<!-- audited: c127f01eb4f0 -->

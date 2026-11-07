# Rails Standards

The Rails app is held by RuboCop, Brakeman, Zeitwerk and RSpec at full
strength.

## The Rule

- Every source `app/<path>.rb` has its twin `spec/<path>_spec.rb`; a
  controller may use `spec/requests/<name>_spec.rb`. `bin/changed` fails a
  changed source with no twin.
- The full suite holds 100% line and branch coverage of `app/`, and every
  changed source is at 100%.
- Ruby runs the suite with warnings on; a warning from the app's own code
  fails it.
- RuboCop autocorrects, then any offense left fails. Brakeman fails on any
  warning. Neither is configured off (`no-lint-exceptions.md`).
- `bin/build` eager-loads the app with Zeitwerk.

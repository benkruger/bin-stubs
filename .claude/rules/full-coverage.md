# Full Coverage

This repo proves that each language's `bin/test` holds the bar
`starter/.claude/rules/full-coverage.md` states and never passes by
measuring nothing.

## The Rule

- `tests/run` runs the green `bin/test` of each language whose
  `bin/test` measures coverage (`typescript`, `javascript`, `python`,
  `rails`, `rust`, `ios`), the way `bin/ci` runs it, and fails unless it
  prints `bin/test: coverage bar held on 1 source(s)`, its test app's one
  source. Trigger: any change to a language's `bin/test` or test app.
- `coverage_gap` plants a source below the bar for each of those
  languages, and `tests/run` fails a language whose `bin/ci` passes the
  plant or whose plant is missing. Trigger: a new language or any change
  to a language's `bin/test`.
<!-- audited: 67bc9bef4520 -->

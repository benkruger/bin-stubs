# Full Coverage

Where `bin/ci` measures coverage, it measures every source at the
full bar the language's standards state.

## The Rule

- On the `--all` run `bin/ci` makes, each language's `bin/test` holds
  every source to the bar `<language>-standards.md` states, and the review
  refuses a coverage config or `bin/test` change that narrows it. Trigger:
  any change to a coverage config or a language's `bin/test`.
- A coverage config measures every target with no filter. `tests/guards`
  checks two: it fails a Ruby file that starts SimpleCov without the line
  `minimum_coverage line: 100, branch: 100` or with an `add_filter`, and
  an `.xctestplan` or `.xcscheme` line matching `COVERAGE_NARROWED`, which
  turns code coverage off or limits it to some targets. Trigger: any
  change to a Ruby file that starts SimpleCov, an `.xctestplan` or an
  `.xcscheme`.
<!-- audited: a39f109afe98 -->

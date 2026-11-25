# Full Coverage

Where `bin/ci` measures coverage, it measures every source at the
full bar the language's standards state.

## The Rule

- On the `--all` run `bin/ci` makes, each language's `bin/test` holds
  every source to the bar `<language>-standards.md` states, and fails a
  run that falls below it, failing `bin/ci`. Trigger: any change to a
  coverage config or a language's `bin/test`.
- A `bin/test` that measures coverage prints `bin/test: coverage bar held
  on N source(s)` once every source it measured meets the bar. A run over
  the whole app fails when it measured no source, and one whose coverage
  tool can finish without writing a report, such as SimpleCov or
  `swift test`, fails when it writes none, so a check never passes by
  measuring nothing; pytest counts as such a tool. Each `bin/test` finds a
  source's row by its exact path, never by a matching tail. Trigger: any
  change to a language's `bin/test`.
- A coverage config measures every target with no filter. `tests/guards`
  fails a Ruby file that starts SimpleCov without the line
  `minimum_coverage line: 100, branch: 100` or with `add_filter`, `skip` or
  `filters`, any `.simplecov` file, an `.xctestplan` or `.xcscheme`
  line matching `COVERAGE_NARROWED`, which turns code coverage off or
  limits it to some targets, and a Vitest or Vite config line naming
  `ignoreClassMethods`, which counts methods that never ran as covered.
  Trigger: any change to a Ruby file that starts SimpleCov, a
  `.simplecov`, an `.xctestplan`, an `.xcscheme` or a Vitest or Vite
  config.
<!-- audited: 9b4a0824ced0 -->

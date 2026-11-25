# Language Parity

Every language ships the same gate and contract, so repos behave alike.

## The Rule

- Each language (`typescript`, `javascript`, `python`, `rails`, `rust`,
  `ios`, `shell`) ships `ci`, `changed`, `format`, `lint`, `build`, `test` and
  `dependencies` where `starter/.claude/rules/gate-scripts.md` places them,
  and `<language>/.claude/rules/<language>-standards.md` stating exactly what
  those scripts enforce, updated with any change to what one enforces.
  `tests/run` fails a language missing one of those scripts or shipping it
  not executable. Trigger: a new language, or a change to what one enforces.
- A language whose apps run a local server (`typescript`, `javascript`,
  `rails`) also ships `open`, which starts the app on 127.0.0.1 and opens
  the browser, and `qa`, which runs its end-to-end tests outside `bin/ci`;
  `tests/run` fails either one that is not executable or does not run its
  stack's command. Trigger: a change to `open` or `qa`.
- Each `bin/ci` runs its four steps at once, prints their `[n/4]` lines, reports
  every failing step, writes the sentinel only after all four pass, skips a step
  whose sentinel holds the tree's hash unless `--force`, clears the sentinel on
  `--clean`, and runs `bin/format --check`, which fails unformatted code and
  rewrites nothing; `bin/format` and `bin/changed` rewrite unformatted code.
  `tests/run` fails serial steps, a missing `[n/4]` line, a stop at the first
  failure, a sentinel written on a red run, a rerun of a passed step, a skip
  under `--force`, a `--clean` that leaves the sentinel, a `--check` that passes
  or rewrites unformatted code, and a `bin/format` or `bin/changed` that leaves
  an edited file unformatted. Trigger: a change to `ci`, `format` or `changed`.
- Each `bin/changed` works out the files changed since the last commit once,
  prints them with `--files`, and runs the other scripts on that list rather
  than calling a tool itself. A script that works file by file takes paths,
  takes the whole app with `--all`, and given neither reads
  `bin/changed --files`; no other script works out the list on its own.
- A behavior added to one language lands in every language it applies to, in
  the same change, with its case in `tests/run`.
- `tests/run` drives every language through green, skip, sibling edit, red,
  `--force`, `--clean`, `bin/changed` on an edited tracked file, and `bin/ci`
  on committed files nothing changed, in a throwaway repo, and fails a
  language whose result in any of them differs from the contract above.
  Trigger: a new language or any change to a language's scripts.
<!-- audited: 739ed2f73ecf -->

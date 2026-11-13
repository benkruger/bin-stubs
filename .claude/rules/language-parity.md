# Language Parity

Every language folder ships the same gate with the same contract, so a repo
behaves the same whatever its stack.

## The Rule

- Each language folder (`typescript`, `javascript`, `python`, `rails`,
  `rust`, `ios`) ships `ci`, `changed`, `format`, `lint`, `build`, `test` and
  `dependencies` in its `bin/`, and `.claude/rules/<language>-standards.md`
  stating exactly what those scripts enforce. A change to what a script
  enforces updates that rule in the same change.
- A language whose apps run a local server (`typescript`, `javascript`,
  `rails`) also ships `bin/open`: it starts the app bound to 127.0.0.1 and
  opens it in the browser.
- Each `bin/ci` prints `[n/4]` step lines, writes the sentinel only after all
  four steps pass, leaves the old sentinel on a red run, and honors `--force`
  and `--clean`. It passes `--all` to every step that would otherwise check
  only the changed files, so each step covers the whole app.
- Each `bin/changed` works out the files changed since the last commit once,
  prints them with `--files`, and runs the other scripts on that list rather
  than calling a tool itself. A script that works file by file takes paths,
  takes the whole app with `--all`, and given neither reads
  `bin/changed --files`; no other script works out the list on its own.
- A behavior added to one language lands in every language it applies to, in
  the same change, with its case in `tests/run`.
- `tests/run` drives each language it can run on the machine through green,
  skip, sibling edit, red, `--force`, `--clean`, `bin/changed` on an edited
  tracked file, and `bin/ci` on committed files nothing changed, in a
  throwaway repo.

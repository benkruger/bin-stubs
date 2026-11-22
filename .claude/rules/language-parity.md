# Language Parity

Every language folder ships the same gate with the same contract, so a repo
behaves the same whatever its stack.

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
- Each `bin/ci` prints `[n/4]` step lines, writes the sentinel only after all
  four steps pass, leaves the old sentinel on a red run, and honors `--force`
  and `--clean`. It passes `--all` to every step that would otherwise check
  only the changed files, so each step covers the whole app. Its format
  step runs `bin/format --check`, which fails on an unformatted file and
  rewrites nothing; `bin/format` without it and `bin/changed` rewrite. A
  step that passes saves the tree's hash in its own sentinel, so a run on
  that tree skips it; `--force` ignores those and `--clean` removes them;
  `tests/run` fails a rerun of a passed step or a skip under `--force`.
  Trigger: any change to a language's `ci`, `format` or `changed`.
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
<!-- audited: 9004782dc5b4 -->

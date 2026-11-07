# Language Parity

Every language folder ships the same gate with the same contract, so a repo
behaves the same whatever its stack.

## The Rule

- Each language folder (`typescript`, `javascript`, `python`, `rails`,
  `rust`, `ios`) ships `ci`, `changed`, `format`, `lint`, `build`, `test` and
  `dependencies` in its `bin/`, and `.claude/rules/<language>-standards.md`
  stating exactly what those scripts enforce. A change to what a script
  enforces updates that rule in the same change.
- Each `bin/ci` prints `[n/4]` step lines, writes the sentinel only after all
  four steps pass, leaves the old sentinel on a red run, and honors `--force`
  and `--clean`.
- A behavior added to one language lands in every language it applies to, in
  the same change, with its case in `tests/run`.
- `tests/run` drives each language it can run on the machine through green,
  skip, sibling edit, red, `--force` and `--clean` in a throwaway repo.

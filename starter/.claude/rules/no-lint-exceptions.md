# No Lint Exceptions

Every linter rule stays on; a finding is fixed in the code it flags, never
silenced.

## The Rule

- No file carries a suppression comment or attribute for any tool the gate
  drives: shellcheck, ESLint, TypeScript, Biome, RuboCop, Ruff, Clippy,
  swift-format, markdownlint, Prettier or a coverage tool. `tests/guards`
  holds the banned list and fails on any of them.
- Lint configuration only makes a tool run; it never turns a rule off or
  loosens it. `tests/guards` rejects Biome `rules` and `overrides`, an
  ESLint severity of `off` or `warn` and any `linterOptions`, a RuboCop
  `Enabled: false` and a Cargo lint set to `allow`.
- When a rule fires, rename, split or restructure until it passes.

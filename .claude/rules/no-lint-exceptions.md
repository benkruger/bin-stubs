# No Lint Exceptions

The kit installs gates that ban silenced lint, so the kit itself carries no
silenced lint anywhere.

## The Rule

- No file in the repo contains a suppression comment for any linter the kit
  drives: shellcheck, ESLint, TypeScript, Biome, RuboCop, Ruff, coverage
  tools or Prettier. `tests/guards` holds the banned list.
- A lint finding is fixed in the code it flags.

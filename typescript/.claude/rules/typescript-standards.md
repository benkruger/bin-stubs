# TypeScript Standards

The TypeScript app is held by Prettier, ESLint, `tsc` and Vitest at full
strength.

## The Rule

- Every source `src/<path>.ts` (or `.tsx`) has its twin
  `tests/<path>.test.ts`. `bin/changed` and `bin/test` fail a changed source
  with no twin.
- Every changed source is at 100% functions, lines, branches and
  statements under Vitest's v8 coverage; a changed test holds its source to
  the same bar.
- Prettier formats every file it has a parser for except Markdown, which
  markdownlint owns.
- ESLint passes with zero warnings on every file its config covers;
  `eslint.config.js` keeps every rule on (`no-lint-exceptions.md`).
- `bin/build` runs the package's `build` script, or type-checks the whole
  app with `tsc --noEmit` when there is none.
- npm installs from `package-lock.json`; `.nvmrc` pins Node, and `bin/ci`
  activates it through nvm and fails unless it is active.

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
- Every file has a formatter and a linter: Prettier and ESLint rules,
  markdownlint for Markdown, or shfmt and shellcheck for a bash script.
  `bin/lint` fails any other file unless `UNGATED_NAMES` or the exact paths
  in `UNGATED_PATHS` name it; a new file type gets its `eslint.config.js`
  block in the same change.
- ESLint passes with zero warnings on every file its config covers;
  `eslint.config.js` keeps every rule on (`no-lint-exceptions.md`).
- `bin/build` runs the package's `build` script, or type-checks the whole
  app with `tsc --noEmit` when there is none.
- npm installs from `package-lock.json`; `.nvmrc` pins Node, and `bin/ci`
  activates it through nvm and fails unless it is active.
- `packageManager` in `package.json` pins npm's exact version; `bin/ci`
  fails unless that npm is active.
- `npm audit` reports no moderate or worse advisory; `bin/ci` fails after
  install otherwise. A vulnerable transitive package is lifted through
  `overrides` in `package.json`.

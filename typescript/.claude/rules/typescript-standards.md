# TypeScript Standards

The TypeScript app is held by Prettier, ESLint, `tsc` and Vitest at full
strength.

## The Rule

- A source is `src/<path>` ending `.ts`, `.tsx`, `.mts` or `.cts`, other
  than a test or a `.d.ts` declaration. Its twin is
  `tests/<path>.test.<ext>` for any of those extensions. `bin/changed` fails
  a changed source with no twin; `bin/ci` fails any source with none, and
  `bin/test` fails a test whose source does not exist.
- Every source is at 100% functions, lines, branches and statements under
  Vitest's v8 coverage. `bin/ci` checks every source; `bin/changed` checks
  the changed ones, and a changed test holds its source to the same bar.
- Every file has one formatter and linter pair: markdownlint (the one on
  PATH) for Markdown, shfmt and shellcheck for a bash script, and Prettier
  and ESLint rules for every other file Prettier has a parser for and
  formats without a pragma. `bin/lint` fails any other file unless
  `UNGATED_NAMES` or the exact paths in `UNGATED_PATHS` name it; a new file
  type gets its `eslint.config.js` block in the same change.
- ESLint passes with zero warnings on every file its config covers;
  `eslint.config.js` keeps every rule on (`no-lint-exceptions.md`).
- `bin/build` runs the package's `build` script when it has one, then
  `tsc --noEmit`, and fails when either fails or `tsc --showConfig` does
  not show `strict` true, no `STRICT_FLAGS` entry false, no `noCheck` and
  every TypeScript file in the app.
- npm installs from `package-lock.json`; `.nvmrc` pins Node, and every
  `bin/` script activates it through nvm and fails unless it is active.
- `packageManager` in `package.json` pins npm's exact version; every `bin/`
  script fails unless that npm is active.
- `npm audit` reports no moderate or worse advisory; `bin/ci` fails
  otherwise. A vulnerable transitive package is lifted through `overrides`
  in `package.json`.
- A `bin/ci` step that exits 0 still fails when its output matches
  `npm warn`, `DeprecationWarning` or a line starting `Warning:` then a
  space, in any case.
- `bin/qa`, outside `bin/ci`, installs Chromium and runs `playwright test`;
  a failed test, or output matching those same warnings, fails it.
- Trigger: any change to a TypeScript `bin/` script or `eslint.config.js`.
<!-- audited: 2bbbd70d6ae7 -->

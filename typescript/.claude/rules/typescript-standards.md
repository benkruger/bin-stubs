# TypeScript Standards

Prettier, ESLint, `tsc` and Vitest hold the TypeScript app at full strength.

## The Rule

- A source is a `.ts`, `.tsx`, `.mts` or `.cts` file below a folder, bar a
  `.d.ts`, `.test` or `.spec` file and those `is_source` in
  `bin/_typescript/lib/sources.sh` leaves out. Its twin is
  `tests/<path>.test.<ext>`, less a leading `src/`. `bin/changed` fails a
  changed source with no twin; `bin/ci` fails any source with none, and
  `bin/test` fails a test whose source does not exist.
- Every source is at 100% functions, lines, branches and statements under
  Vitest's v8 coverage. `bin/ci` checks every source; `bin/changed` checks
  the changed ones, and a changed test holds its source to the same bar.
- Every file has one formatter and linter pair: markdownlint (the one on
  PATH) for Markdown, shfmt and shellcheck for a bash script, and Prettier
  and ESLint rules for every other file Prettier has a parser for and
  formats with no pragma setting. `bin/lint` fails any other file unless
  `UNGATED_NAMES` or the exact paths in `UNGATED_PATHS` name it; a new file
  type gets its `eslint.config.js` block in the same change.
- ESLint passes with zero warnings (`no-lint-exceptions.md`); `bin/lint` fails
  a file whose config sets a processor or another language, or leaves off a
  rule or the package of its recommended set: `@eslint/js` for a script,
  plus `typescript-eslint` for TypeScript, `@eslint/json` for JSON and
  `@eslint/css` for CSS, bar a core rule with its `@typescript-eslint/` twin on.
- `bin/build` runs the package's `build` script, if any, then `tsc --noEmit`,
  and fails when either fails or `tsc --showConfig` does not show `strict`
  true, no `STRICT_FLAGS` entry false, no `noCheck` and every TypeScript
  file in the app, or shows `skipLibCheck` over the app's own `.d.ts` file.
- npm installs from `package-lock.json`. Outside CI, every `bin/` script
  activates the Node `.nvmrc` pins through nvm, and fails unless it and the
  npm `packageManager` pins in `package.json` are active.
- `npm audit` finds no moderate or worse advisory, or `bin/ci` fails; a
  vulnerable transitive package lifts through `package.json` `overrides`.
- A `bin/ci` step that exits 0 still fails on output matching `npm warn`,
  `DeprecationWarning` or a line starting `Warning:` and a space, any case.
- `bin/qa`, outside `bin/ci`, installs Chromium and runs `playwright test`;
  a failed test, or output matching those same warnings, fails it.
- Trigger: any change to a TypeScript `bin/` script or `eslint.config.js`.
<!-- audited: 353a8ed61eda -->

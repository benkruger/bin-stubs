# TypeScript Standards

Prettier, ESLint, `tsc` and Vitest hold the TypeScript app at full strength.

- A source is a `.ts`, `.tsx`, `.mts` or `.cts` file that `is_source` accepts:
  one in a subfolder, outside `tests/`, `e2e/`, `node_modules/`, `dist/`,
  `public/` and `coverage/`, and not a `.test`, `.spec`, `.d.ts`, `.d.mts`
  or `.d.cts` file. Its twin is `tests/<path>.test.<ext>`, less a leading
  `src/`. `bin/changed` fails a changed source with no twin, `bin/ci` any,
  and `bin/test` a named one; it runs its twin and fails a TypeScript `.test` or
  `.spec` file outside `e2e/` and `node_modules/` that is no source's twin.
- Every source is at 100% functions, lines, branches and statements under
  Vitest's v8 coverage. `bin/ci` checks every source; `bin/changed` checks the
  changed ones, a changed test holding its source to the same bar. `bin/test`
  fails a source a Vitest `setupFiles` entry names: Vitest never measures it.
- `bin/format` runs Prettier on every file it has a parser for but Markdown, a
  symlink, `node_modules/`, `.venv/`, `.flow-states/` and the apps inside a root
  app. `bin/lint` leaves Markdown and bash scripts to `tests/guards` and fails
  any other file but a symlink that Prettier ignores or has no parser for, whose
  Prettier config sets `requirePragma` or `checkIgnorePragma`, or that no ESLint
  rule covers, unless `UNGATED_NAMES` or an exact `UNGATED_PATHS` path names it.
- ESLint passes with zero warnings (`no-lint-exceptions.md`); `bin/lint` fails
  a file whose config sets a processor or another language, or leaves off a
  rule or the package of its recommended set: `@eslint/js` for a script,
  plus `typescript-eslint` for TypeScript, `@eslint/json` for JSON and
  `@eslint/css` for CSS, bar a core rule with its `@typescript-eslint/` twin on.
- `bin/build` runs the package's `build` script, if any, then `tsc --noEmit`,
  and fails when either fails or `tsc --showConfig` does not show `strict`
  true, no `STRICT_FLAGS` entry false, no `noCheck` and every TypeScript
  file in the app, or shows `skipLibCheck` over the app's own `.d.ts` file.
- `packageManager` pins npm, which installs from `package-lock.json`. Every
  `bin/` script disables Node's `TMPDIR` compile cache and, outside CI,
  activates the `.nvmrc` Node through nvm and fails unless both pins are active.
- `npm audit` finds no moderate or worse advisory, or `bin/ci` fails; a
  vulnerable transitive package lifts through `package.json` `overrides`.
- A `bin/ci` step that exits 0, or `bin/qa`, which runs outside `bin/ci`,
  installs Chromium and runs `playwright test`, still fails on output
  matching `npm warn`, `DeprecationWarning` or a line starting `Warning:`
  and a space, any case; a failed test fails `bin/qa`.
- Trigger: any change to a TypeScript `bin/` script or `eslint.config.js`.
<!-- audited: 83ec9d7a995a -->

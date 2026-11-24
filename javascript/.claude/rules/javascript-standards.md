# JavaScript Standards

The JavaScript app is held by Biome and its own test script under c8 at full
strength.

## The Rule

- A source is a `.js`, `.mjs`, `.cjs` or `.jsx` file below a directory;
  `is_source` in `bin/_javascript/test` and `bin/_javascript/changed` names
  the directories it leaves out. Root-level files are configuration.
- Every source has a twin test named `tests/<path>.test.<ext>`,
  `tests/<path>.spec.<ext>`, `<dir>/<name>.test.<ext>`,
  `<dir>/<name>.spec.<ext>` or `<dir>/test-<name>.<ext>`, where `<ext>` is
  `js`, `mjs`, `cjs` or `jsx`; `bin/changed` and `bin/test` share that one
  list, so a changed test holds its source too. `bin/changed` fails a changed
  source with no twin; `bin/ci` fails any source with none, and `bin/test`
  fails a test whose source does not exist and runs a named source's twin.
- Every source is at 100% functions, lines, branches and statements under
  c8. `bin/ci` checks every source; `bin/changed` checks the changed ones.
- Biome formats and lints every file except Markdown (markdownlint, the one
  on PATH) and bash scripts (shfmt and shellcheck). `bin/lint` fails any
  other file type unless `UNGATED_NAMES` or the exact paths in
  `UNGATED_PATHS` name it. Biome passes with zero warnings.
- `biome.json` keeps every rule on (`no-lint-exceptions.md`).
- `bin/build` runs the package's `build` script, if any, then `node --check`
  on every `.js`, `.mjs` and `.cjs` file, bar those of the apps inside a
  root app, and fails when either fails.
- `.nvmrc` pins Node and `packageManager` in `package.json` pins npm, which
  installs from `package-lock.json`; outside CI, every `bin/` script
  activates Node through nvm and fails unless both pins are active.
- `npm audit` finds no moderate or worse advisory, or `bin/ci` fails; a
  vulnerable transitive package lifts through `package.json` `overrides`.
- `bin/dependencies` updates packages as `packages.md` states, then
  rewrites `biome.json` with `biome migrate --write` to match the
  installed Biome.
- A `bin/ci` step that exits 0 still fails on output matching `npm warn`,
  `DeprecationWarning` or a line starting `Warning:` and a space, any case.
- `bin/qa`, outside `bin/ci`, installs Chromium and runs `playwright test`;
  a failed test, or output matching those same warnings, fails it.
- Trigger: any change to a JavaScript `bin/` script.
<!-- audited: 66147b52a3aa -->

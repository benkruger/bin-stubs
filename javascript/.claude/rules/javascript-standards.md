# JavaScript Standards

Biome and the app's own tests under c8 hold the JavaScript app at full strength.

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
- `bin/lint` skips `node_modules/` and `.flow-states/` at any depth, a top-level
  `dist/` and the apps inside a root app; Biome formats and lints every other
  `.js`, `.mjs`, `.cjs`, `.jsx`, `.json`, `.jsonc` and `.css` file with zero
  warnings on the recommended or stricter rules `no-lint-exceptions.md` allows;
  it leaves Markdown and bash scripts to `tests/guards` and fails any other
  file but a symlink unless `UNGATED_NAMES` or `UNGATED_PATHS` names it.
- `bin/build` runs the package's `build` script, if any, then `node --check`
  on every `.js`, `.mjs` and `.cjs` file, bar those of the apps inside a
  root app, and fails when either fails.
- `.nvmrc` pins Node and `packageManager` in `package.json` pins npm, which
  installs from `package-lock.json`; outside CI, every `bin/` script
  activates Node through nvm and fails unless both pins are active.
- `npm audit` finds no moderate or worse advisory, or `bin/ci` fails; a
  vulnerable transitive package lifts through `package.json` `overrides`.
- `bin/dependencies` updates packages as `packages.md` states, then rewrites
  `biome.json` with `biome migrate --write` to match the installed Biome.
- A `bin/ci` step that exits 0 still fails on output matching `npm warn`,
  `DeprecationWarning` or a line starting `Warning:` and a space, any case.
- `bin/qa`, outside `bin/ci`, installs Chromium and runs `playwright test`;
  a failed test, or output matching those same warnings, fails it.
- Trigger: any change to a JavaScript `bin/` script.
<!-- audited: a005ac0129ba -->

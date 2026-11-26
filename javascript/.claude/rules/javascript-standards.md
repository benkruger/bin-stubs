# JavaScript Standards

Biome and the app's own tests under c8 hold the JavaScript app at full strength.

## The Rule

- A source is a `.js`, `.mjs`, `.cjs` or `.jsx` file below a directory;
  `is_source`, which `bin/changed` and `bin/test` share, names the
  directories it leaves out. Root-level files are configuration, and `e2e/`
  holds `bin/qa`'s specs, which are neither sources nor tests.
- Every source has a twin test named `tests/<path>.test.<ext>`,
  `tests/<path>.spec.<ext>`, `<dir>/<name>.test.<ext>`,
  `<dir>/<name>.spec.<ext>` or `<dir>/test-<name>.<ext>`, where `<ext>` is
  `js`, `mjs`, `cjs` or `jsx`; `bin/changed` and `bin/test` share that one
  list, so a changed test holds its source too. `bin/changed` fails a changed
  source with no twin, `bin/ci` any, and `bin/test` a named one; `bin/test`
  runs a named source's twin and fails a test whose source does not exist.
- Every source is at 100% functions, lines, branches and statements under
  c8. `bin/ci` checks every source; `bin/changed` checks the changed ones.
- `bin/lint` skips `node_modules/` and `.flow-states/` at any depth, a top-level
  `dist/` and the apps inside a root app; Biome lints every other `.js`, `.mjs`,
  `.cjs`, `.jsx`, `.json`, `.jsonc` and `.css` file with zero warnings on the
  rules `no-lint-exceptions.md` allows, and `bin/format` formats the same files;
  `bin/lint` leaves Markdown and bash scripts to `tests/guards` and fails any
  other file but a symlink unless `UNGATED_NAMES` or `UNGATED_PATHS` names it.
- `bin/build` runs the package's `build` script, if any, then `node --check`
  on every `.js`, `.mjs` and `.cjs` file, bar those of the apps inside a
  root app, and fails when either fails.
- `.nvmrc` pins Node and `packageManager` pins npm, which installs from
  `package-lock.json`. Every `bin/` script disables Node's compile cache and,
  outside CI, activates Node through nvm and fails unless both pins are active.
- `npm audit` finds no moderate or worse advisory, or `bin/ci` fails; a
  vulnerable transitive package lifts through `package.json` `overrides`.
- `bin/dependencies` updates packages as `packages.md` states, then rewrites
  `biome.json` with `biome migrate --write` to match the installed Biome.
- A `bin/ci` step that exits 0, or `bin/qa`, which runs outside `bin/ci`,
  installs Chromium and runs `playwright test`, still fails on output
  matching `npm warn`, `DeprecationWarning` or a line starting `Warning:`
  and a space, any case; a failed test fails `bin/qa`.
- Trigger: any change to a JavaScript `bin/` script.
<!-- audited: d1e319dd39ff -->

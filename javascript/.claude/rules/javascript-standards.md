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
  fails a test whose source does not exist.
- Every source is at 100% functions, lines, branches and statements under
  c8. `bin/ci` checks every source; `bin/changed` checks the changed ones.
- Biome formats and lints every file except Markdown (markdownlint, the one
  on PATH) and bash scripts (shfmt and shellcheck). `bin/lint` fails any
  other file type unless `UNGATED_NAMES` or the exact paths in
  `UNGATED_PATHS` name it. Biome passes with zero warnings.
- `biome.json` keeps every rule on (`no-lint-exceptions.md`).
- `.nvmrc` pins Node and `packageManager` in `package.json` the package
  manager's exact version; outside CI, every `bin/` script activates Node
  through nvm and fails unless both are active.
- The lockfile's package manager audits with no moderate or worse advisory;
  `bin/ci` fails otherwise. A vulnerable transitive package is
  lifted through the package manager's overrides.
- `bin/dependencies` updates packages as `packages.md` states, then
  rewrites `biome.json` with `biome migrate --write` to match the
  installed Biome.
- A `bin/ci` step that exits 0 still fails when its output matches
  `npm warn`, `DeprecationWarning` or a line starting `Warning:` then a
  space, in any case.
- `bin/qa`, outside `bin/ci`, installs Chromium and runs `playwright test`;
  a failed test, or output matching those same warnings, fails it.
- Trigger: any change to a JavaScript `bin/` script.
<!-- audited: 589ef09d7d98 -->

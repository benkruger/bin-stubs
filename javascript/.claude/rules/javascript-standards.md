# JavaScript Standards

The JavaScript app is held by Biome and its own test script under c8 at full
strength.

## The Rule

- A source is any `.js`, `.mjs`, `.cjs` or `.jsx` file below a directory,
  outside `tests/`, `dist/`, `public/` and `node_modules/`. Root-level files
  are configuration.
- Every source has a twin: the first that exists of
  `tests/<path>.test.js` (or `.mjs`), `<dir>/<name>.test.js` (or `.mjs`), or
  `<dir>/test-<name>.mjs` (or `.js`). `bin/changed` fails a changed source
  with no twin.
- Every changed source is at 100% functions, lines, branches and
  statements under c8.
- Biome formats and lints every file except Markdown (markdownlint) and
  bash scripts (shfmt and shellcheck). `bin/lint` fails any other file type
  unless `UNGATED_NAMES` or the exact paths in `UNGATED_PATHS` name it.
- `biome.json` keeps every rule on (`no-lint-exceptions.md`).
- `.nvmrc` pins Node; every `bin/` script activates it through nvm and
  fails unless it is active.
- `packageManager` in `package.json` pins the package manager's exact
  version; every `bin/` script fails unless that version is active.
- The lockfile's package manager audits with no moderate or worse advisory;
  `bin/ci` fails after install otherwise. A vulnerable transitive package is
  lifted through the package manager's overrides.

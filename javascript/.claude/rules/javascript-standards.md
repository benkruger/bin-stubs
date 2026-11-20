# JavaScript Standards

The JavaScript app is held by Biome and its own test script under c8 at full
strength.

## The Rule

- A source is a `.js`, `.mjs`, `.cjs` or `.jsx` file below a directory;
  `is_source` in `bin/test` and `bin/changed` names the directories it
  leaves out. Root-level files are configuration.
- Every source has a twin test named `tests/<path>.test.<ext>`,
  `tests/<path>.spec.<ext>`, `<dir>/<name>.test.<ext>`,
  `<dir>/<name>.spec.<ext>` or `<dir>/test-<name>.<ext>`, where `<ext>` is
  `js`, `mjs`, `cjs` or `jsx`; `bin/changed` and `bin/test` share that one
  list, so a changed test holds its source too. `bin/changed` fails a changed
  source with no twin; `bin/ci` fails any source with none.
- Every source is at 100% functions, lines, branches and statements under
  c8. `bin/ci` checks every source; `bin/changed` checks the changed ones.
- Biome formats and lints every file except Markdown (markdownlint, the one
  on PATH) and bash scripts (shfmt and shellcheck). `bin/lint` fails any
  other file type unless `UNGATED_NAMES` or the exact paths in
  `UNGATED_PATHS` name it.
- `biome.json` keeps every rule on (`no-lint-exceptions.md`).
- `.nvmrc` pins Node; every `bin/` script activates it through nvm and
  fails unless it is active.
- `packageManager` in `package.json` pins the package manager's exact
  version; every `bin/` script fails unless that version is active.
- The lockfile's package manager audits with no moderate or worse advisory;
  `bin/ci` fails after install otherwise. A vulnerable transitive package is
  lifted through the package manager's overrides.
- Trigger: any change to a JavaScript `bin/` script.
<!-- audited: 51ec75382f12 -->

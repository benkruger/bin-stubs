# Packages

Only `bin/dependencies` installs an app's packages; every other gate
script of a language with a manifest checks that they are there and
match it or its lockfile.

## The Rule

- `bin/dependencies` updates an app's packages to the newest versions its
  manifest allows, then installs them. `tests/guards` fails a
  `dependencies` script directly under a `bin/_<language>/` folder that
  has a line matching `INSTALL_COMMANDS` (npm, pnpm, yarn or bun
  `install`, `i`, `ci`, `add`, `update` or `upgrade`; uv `sync`, `add`,
  `lock` or `pip`; bundle `install`, `update`, `add` or `lock`; cargo
  `fetch`, `update`, `add` or `generate-lockfile`; `swift package update`
  or `resolve`; `xcodebuild -resolvePackageDependencies`), and none
  matching `UPDATE_COMMANDS`, an `update`,
  `upgrade` or `--upgrade` argument. It fails a line matching
  `INSTALL_COMMANDS` in any other script directly under such a folder.
  Trigger: any change to a gate script.
- Every other gate script of a language whose
  `bin/_<language>/lib/toolchain.sh` defines `packages_check` runs it, and
  it fails with "run bin/dependencies" when the packages are missing or do
  not match the manifest or lockfile. `tests/guards` fails a `ci`,
  `changed`, `format`, `lint`, `build`, `test`, `open` or `qa` script
  directly under that `bin/_<language>/` folder that never names
  `packages_check`. Trigger: any change to how a gate script gets its
  packages.
<!-- audited: 03cdfbfcec28 -->

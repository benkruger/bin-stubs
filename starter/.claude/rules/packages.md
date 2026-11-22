# Packages

Only `bin/dependencies` installs an app's packages; every other gate
script of a language with a manifest checks that they are there and
match it or its lockfile.

## The Rule

- `bin/dependencies` updates an app's packages to the newest versions its
  manifest allows, then installs them; the review refuses one that only
  installs. `tests/guards` fails a line in any other script directly
  under a `bin/_<language>/` folder that matches `INSTALL_COMMANDS`,
  which names the package managers' install, update and add commands.
  Trigger: any change to a gate script.
- Every other gate script of a language with a package manifest runs
  its language's `packages_check`, which fails with "run
  bin/dependencies" when the packages are missing or do not match the
  manifest or lockfile; the review refuses a gate script that skips it.
  Trigger: any change to how a gate script gets its packages.
<!-- audited: 7f2dbc8fffe4 -->

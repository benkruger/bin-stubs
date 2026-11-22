# Shell Standards

A shell app, a folder no other language claims that holds an
executable `test/run`, is held by shfmt, shellcheck and its own tests.

## The Rule

- A shell script is a `.sh` or `.bash` file, or one whose shebang runs
  `bash` or `sh`. `bin/format` writes each one as `shfmt -i 2 -ci` does,
  and with `--check` fails on a file it would change and rewrites nothing;
  `bin/lint` fails on any `shellcheck -x -P SCRIPTDIR` finding.
  Trigger: a change to shell `bin/format` or `bin/lint`.
- `bin/build` fails a script with a shebang that is not executable, a
  script `bash -n` cannot parse, and an app with no executable `test/run`.
  Trigger: a change to shell `bin/build`.
- `bin/test` runs `test/run` and fails when it does.
  Trigger: a change to shell `bin/test`.
- `bin/changed` runs `bin/format` and `bin/lint` on the changed scripts,
  then runs `test/run` whenever anything in the app changed.
  `bin/dependencies` updates nothing and exits 0.
  Trigger: a change to shell `bin/changed` or `bin/dependencies`.
<!-- audited: 032db68fc655 -->

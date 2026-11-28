# CI Time

An app's full `bin/ci` runs at most 20%, or under 5 seconds, over its
recorded time on each machine under the same load.

## The Rule

- Each app's `.ci-timeout` holds one `<host> <apps> <seconds>` line per
  machine and load, `<host>` being `hostname -s` less any trailing
  `-<number>` and `<apps>` how many apps that `bin/ci` ran at once.
  After a root `bin/ci` runs all four of an app's steps and they pass,
  `bin/_ci-timeout` fails when the run's time, its load or the line for
  that machine and load is not a whole number, it finds no hostname, or
  the run is more than 20% and at least 5 seconds over that line, and
  keeps the line; `bin/_dispatch` then fails the run and drops the app's
  sentinels; any other pass off `main` writes its time to that line.
  `.ci-timeout` is committed and left out of fingerprints and dirty
  checks. Trigger: any change to `bin/_ci-timeout` or to how `bin/ci`
  times an app.
- `bin/commit` stops `bin/ci` after `FLOW_CI_TIMEOUT_MS` milliseconds
  when that is a whole number above 0, else after five minutes plus, for
  each app with a line for this machine whose time is a whole number above
  0, the largest such time, a fifth more and 5 seconds, so a hung app or
  suite never holds a commit open; it then refuses the commit with `gate
  timed out after <N>s`. Trigger: any change to how `bin/commit` bounds
  `bin/ci`.
<!-- audited: 95c062c6102a -->

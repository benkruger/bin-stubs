# CI Time

An app's full `bin/ci` runs at most 20%, or under 5 seconds, over its
recorded time on each machine.

## The Rule

- Each app's `.ci-timeout` holds one `<host> <seconds>` line per machine.
  After a root `bin/ci` runs all four of an app's steps and they pass,
  `bin/_ci-timeout` fails when the run's time or that machine's line is
  not a whole number of seconds, it finds no hostname, or the run is more
  than 20% and at least 5 seconds over that line, and keeps the line;
  `bin/_dispatch` then fails the run and drops the app's sentinels; any
  other pass off `main` writes its time. `.ci-timeout` is committed and
  left out of fingerprints and dirty checks. Trigger: any change to
  `bin/_ci-timeout` or to how `bin/ci` times an app.
- `bin/commit` stops `bin/ci` after `FLOW_CI_TIMEOUT_MS` milliseconds
  when that is a whole number above 0, else after five minutes plus, for
  each app whose line for this machine is a whole number, that line's
  time, a fifth more and 5 seconds, so a hung app or suite never holds a
  commit open; it then refuses the commit with `gate timed out after
  <N>s`. Trigger: any change to how `bin/commit` bounds `bin/ci`.
<!-- audited: 8f0cf1fc03da -->

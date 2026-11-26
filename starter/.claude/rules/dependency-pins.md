# Dependency Pins

A dependency held back, overridden or patched is a dated exception, so it
lasts only as long as its reason.

## The Rule

- A pin is a dependency held below its latest release, overridden to
  another version, patched, or installed from outside its registry.
- Every pin lands with its check in `checks/`: an executable script that
  names the pin and its reason, holds a `revisit=YYYY-MM-DD` line at most
  30 days out, and fails from that date. `bin/_root-tests` runs every
  check on every `bin/ci` but `--clean`, with no app flag or with
  `--suite`, so the date fires on an unchanged tree, and fails a check
  with no such line or with a date more than 30 days out.
- On the revisit date the pin goes if its reason is gone; otherwise the
  check gets a new date and states the reason as it stands then.
<!-- audited: 9b838ac9ac19 -->

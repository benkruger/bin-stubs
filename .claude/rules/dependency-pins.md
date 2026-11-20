# Dependency Pins

A pin in this repo follows `starter/.claude/rules/dependency-pins.md`, and
the test apps `tests/run` builds count as part of this repo.

## The Rule

- A pin, as `starter/.claude/rules/dependency-pins.md` defines it, that
  `tests/run` makes for a test app has its dated check in `checks/`.
  Trigger: any change to how `tests/run` installs a test app's
  dependencies.
<!-- audited: 908fbc96f4c0 -->

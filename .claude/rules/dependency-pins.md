# Dependency Pins

A pin in this repo follows `starter/.claude/rules/dependency-pins.md`, and
the test apps `tests/run` builds count as part of this repo.

## The Rule

- A pin, as `starter/.claude/rules/dependency-pins.md` defines it, that
  `tests/run` makes for a test app has its dated check in `checks/`;
  `tests/run` fails, in the `typescript`, `javascript`, `python` and
  `rails` test apps, a `package.json` `dependencies` or
  `devDependencies` spec other than `latest`, an override, an
  unindented single-quoted `Gemfile` gem with a version or a
  double-quoted `pyproject.toml` requirement whose bare name is
  followed first by `==`, `<`, `~=`, `!=` or `@` that no file in
  `checks/` names. Trigger: any change to how `tests/run` installs a
  test app's dependencies.
<!-- audited: eff3fb1e108c -->

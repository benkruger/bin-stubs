# No Lint Exceptions

This repo holds itself to `starter/.claude/rules/no-lint-exceptions.md`,
which `starter/tests/guards` enforces here too.

## The Rule

- A rule or doc names a banned suppression token by what it does, never by
  spelling it out, so `starter/tests/guards` never fails on its own
  description; a check builds the token at run time (`guard-tests.md`).
  Trigger: any rule, doc or check that refers to a suppression.
<!-- audited: d38b4ba5988a -->

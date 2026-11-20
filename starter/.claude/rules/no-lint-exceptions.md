# No Lint Exceptions

Every linter rule stays on; a finding is fixed in the code it flags, never
silenced.

## The Rule

- The only comments a tool reads in code are those
  `script-standards.md` allows; `tests/guards` fails any other suppression
  token it knows (`BANNED_SUPPRESSIONS`).
- Lint configuration holds only the files a tool reads, its plugins and
  ruleset, and the target version; `tests/guards` fails a key outside
  that set that turns a rule down.
- Trigger: a lint finding on changed code. Rename, split or restructure the
  code until the rule passes.
<!-- audited: 2fc9af21cf60 -->

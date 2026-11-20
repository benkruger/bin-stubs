# No Lint Exceptions

Every linter rule stays on; a finding is fixed in the code it flags, never
silenced.

## The Rule

- Every finding a tool the gate drives reports is fixed in the code.
  Trigger: any lint finding; rename, split or restructure the code until
  the rule passes. A shellcheck `source=` directive is not a suppression
  (`script-standards.md`).
- Lint configuration holds only the files a tool reads, its plugins and
  ruleset, and the target version; `tests/guards` accepts only those keys
  and fails a setting outside that set. Trigger: any edit to a lint
  configuration file.
- Suppression comments are free-form, so `tests/guards` fails any token in
  `BANNED_SUPPRESSIONS`. Trigger: any edit to a file it scans.
<!-- audited: 51e9cc8015de -->

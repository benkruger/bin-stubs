# No Lint Exceptions

Every linter rule stays on; a finding is fixed in the code it flags, never
silenced.

## The Rule

- Every finding a tool the gate drives reports is fixed by renaming,
  splitting or restructuring the code it flags; `bin/ci` fails while
  any finding stands. Trigger: any lint finding. The one shellcheck
  comment allowed is the one `script-standards.md` names.
- A lint configuration file holds only the settings on its tool's list in
  `tests/guards`: the files the tool reads, its plugins and shared
  rulesets, and the target version. `tests/guards` fails any other
  setting. A tool whose list is empty, such as markdownlint, takes no
  config file. Trigger: any edit to a lint configuration file.
- A comment directs a tool only through the shellcheck directive
  `script-standards.md` allows; `tests/guards` checks this by failing any
  token in `BANNED_SUPPRESSIONS`. Trigger: any edit to a file it scans.
<!-- audited: 06a4661c3b0a -->

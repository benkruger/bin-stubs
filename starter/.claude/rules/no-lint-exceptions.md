# No Lint Exceptions

Every linter rule stays on except one only a comment can satisfy; a finding
is fixed in the code it flags, never silenced.

## The Rule

- Every finding a tool the gate drives reports is fixed by renaming,
  splitting or restructuring the code it flags; `bin/ci` fails while
  any finding stands. Trigger: any lint finding. The one shellcheck
  comment allowed is the one `script-standards.md` names.
- A lint configuration file passes the check `tests/guards` runs for
  its tool: an allowed key list for Biome (linter enabled true;
  `linter.rules` only `preset` `all` and a group in `BIOME_GROUPS` at
  `error`), RuboCop (NewCops enable; any other cop only `Enabled: true`,
  bar `Style/Documentation`, which may be `Enabled: false` since it asks
  for the comment `no-comments.md` bans), Ruff (any `[format]` key) and
  `.shellcheckrc`; for ESLint, no `linterOptions` and every `rules` entry
  at `error`; only warn, deny or forbid levels for Cargo; every
  swift-format rule true. `tests/guards` fails the file that does not. A
  markdownlint config file or `brakeman.ignore` fails outright: those
  tools run on defaults. Trigger: any edit to a lint configuration file.
- Code reaches every linter unsilenced. Suppression comments are free
  text, so `tests/guards` fails each one it names in `BANNED_SUPPRESSIONS`.
  Trigger: any edit to a file it scans.
<!-- audited: b98ab166759c -->

# No Lint Exceptions

Every linter rule stays on except one only a comment can satisfy; a finding
is fixed in the code it flags, never silenced.

## The Rule

- Every finding a tool the gate drives reports, warnings included, is
  fixed by renaming, splitting or restructuring the code it flags;
  `bin/ci` fails while any finding stands. Trigger: any lint finding. The
  one shellcheck comment allowed is the one `script-standards.md` names.
- A lint configuration file passes the check `tests/guards` runs for
  its tool: an allowed key list for Biome (linter enabled true;
  `linter.rules` only `preset` `all` and a group in `BIOME_GROUPS` at
  `error`; `files` only the keys in `BIOME_FILES_KEYS`; `formatter` only
  those in `BIOME_FORMATTER_KEYS`, enabled true; assist only on), RuboCop
  (NewCops enable; `require` and `plugins` only gem names; any other cop
  only `Enabled: true`, bar `Style/Documentation`, which may be
  `Enabled: false` since it asks for the comment `no-comments.md` bans),
  Ruff (any `[format]` key), mypy (`[tool.mypy]` only the keys in
  `MYPY_KEYS`) and `.shellcheckrc`; for ESLint, no `linterOptions`, every
  `rules` entry at `error` in an object literal, and imports only from
  `ESLINT_PACKAGES`; only warn, deny or forbid levels for Cargo, and no
  `-A`, `--allow` or `--cap-lints` flag in a Cargo config's `rustflags`;
  every swift-format rule true; rustfmt on for every file. `tests/guards`
  fails the file that does not. A markdownlint, Clippy or Brakeman config
  file, `brakeman.ignore` and a `.rubocop` options file fail outright:
  those tools run on defaults and the options `bin/lint` passes. So do
  `mypy.ini`, `.mypy.ini` and any `[mypy` section in `setup.cfg`,
  per-module ones included: mypy's settings live in `pyproject.toml`. A
  `.prettierignore` fails outright: Prettier formats every file. Trigger:
  any new or edited lint or format config file.
- Code reaches every linter unsilenced. Suppression comments are free
  text, so `tests/guards` fails each one it names in `BANNED_SUPPRESSIONS`,
  and each Rust attribute matching `RUST_QUIET_ATTRS`, which allows or
  expects a lint or skips rustfmt. Trigger: any edit to a file it scans.
<!-- audited: 5f39bcdeb6f8 -->

# No Lint Exceptions

Every linter rule stays on except one only a comment can satisfy; a finding
is fixed in the code it flags, never silenced.

## The Rule

- Every finding a tool the gate drives reports, warnings included, is
  fixed by renaming, splitting or restructuring the code it flags;
  `bin/ci` fails while any finding stands. Trigger: any lint finding.
- A lint configuration file, or a symlink by its name, passes the check
  `tests/guards` runs for its tool, whatever table or quoting form a key
  takes. Biome: top-level keys in `BIOME_KEYS`; `linter` only `enabled`, true,
  and `rules`: `preset` `all` and a group in `BIOME_GROUPS` at `error`; `files`
  keys in `BIOME_FILES_KEYS`; `formatter` keys in `BIOME_FORMATTER_KEYS`,
  enabled true; `assist` only `enabled` and `actions`, each on. RuboCop:
  top-level keys in `RUBOCOP_KEYS`, or any other key set only to
  `Enabled: true`, bar `Style/Documentation`, which may be `Enabled: false`;
  `AllCops` keys in `RUBOCOP_ALLCOPS_KEYS`, NewCops enable; `require` and
  `plugins` gem names. Ruff: keys in `RUFF_KEYS`, lint keys in
  `RUFF_LINT_KEYS`, any `format` key. mypy: `[tool.mypy]` keys in `MYPY_KEYS`,
  no plugin from the app's own code. `.shellcheckrc` or `shellcheckrc`: each
  directive in `SHELLCHECKRC_KEYS`. ESLint: no `linterOptions`, every `rules`
  entry a bare `error` or `2`, with no options, in an object literal, imports
  only from `ESLINT_PACKAGES`. Cargo: warn, deny or forbid for every lint in a
  `[lints]` entry; no `-A`, `--allow` or `--cap-lints` in a config's
  `rustflags`. swift-format: every rule true. rustfmt: on for every file.
  `tests/guards` fails the file that does not. A markdownlint, Clippy or
  Brakeman config file, `brakeman.ignore` and a `.rubocop` options file
  fail outright: those tools run on defaults and the options `bin/lint`
  passes. So do `mypy.ini`, `.mypy.ini` and any `[mypy` section in
  `setup.cfg`, per-module ones included: mypy's settings live in
  `pyproject.toml`. A `.prettierignore` fails outright: Prettier formats
  every file. Trigger: any new or edited lint or format config file.
- Code reaches every linter unsilenced. Suppression comments are free
  text, so `tests/guards` fails each one it names in `BANNED_SUPPRESSIONS`,
  which also lists the Ruby assignments that switch warnings off, and each Rust
  attribute or `cfg!` matching `RUST_QUIET_ATTRS`, which allows or expects a
  lint, ignores a test, skips rustfmt or hides code from coverage.
  Trigger: any edit to a file it scans.
<!-- audited: 1abf2840b9aa -->

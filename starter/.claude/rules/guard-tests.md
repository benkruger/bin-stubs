# Guard Tests

Every standard the repo holds itself to has a check that fails when the
standard breaks, and `bin/ci` runs it.

## The Rule

- `tests/run` is the repo-level suite `bin/ci` runs. It runs `tests/guards`,
  which checks the file-size cap (`authored-file-size.md`), suppression
  comments and lint configuration (`no-lint-exceptions.md`), every bash
  script (`script-standards.md`), every Markdown file (markdownlint with its
  default rules), `CLAUDE.md` (`claude-md.md`), every rule's shape and audit
  stamp (`rule-authoring.md`), and `.claude/settings.json`: it allows
  `Bash(bin/*)`, denies destructive git, and wires both hooks in
  `.claude/hooks/`.
- `tests/run` pins every cap in `tests/guards` (`authored-file-size.md`,
  `claude-md.md`, `rule-authoring.md`). Changing a cap edits both files in
  the same change.
- A new standard lands with its check in the same change.
<!-- audited: 994a7d1a2dc5 -->

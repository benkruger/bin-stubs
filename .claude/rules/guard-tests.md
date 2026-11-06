# Guard Tests

Every standard this repo holds itself to has a check that fails when the
standard breaks, and `bin/ci` runs it.

## The Rule

- `tests/guards` checks the scripts (shellcheck, strict mode, executable
  entry points), bans suppression comments, and checks the size and shape
  of `CLAUDE.md` and every rule.
- `tests/run` runs `tests/guards` first, then pins its caps: rules at 40
  lines and 8,000 characters, `CLAUDE.md` at 400 lines and 12,000
  characters. Changing a cap edits both files in the same change.
- A new standard, script or helper lands with its check.
- A check never contains a token it bans; it builds the token so the text
  does not match itself.

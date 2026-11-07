# Guard Tests

Every standard the repo holds itself to has a check that fails when the
standard breaks, and `bin/ci` runs it.

## The Rule

- `tests/run` is the repo-level suite `bin/ci` runs. It runs `tests/guards`,
  which checks the file-size cap, suppression comments, lint configuration,
  every bash script, and the size and shape of `CLAUDE.md` and every rule.
- `tests/run` pins every cap in `tests/guards`: rules at 40 lines and 8,000
  characters, `CLAUDE.md` at 400 lines and 12,000 characters, authored files
  at 65,536 bytes. Changing a cap edits both files in the same change.
- Every rule leads with one H1, has no frontmatter and no "Why" or
  "History" heading, reads in the present tense, and cites only rules that
  exist. `CLAUDE.md` never points at the rules.
- A new standard lands with its check in the same change.

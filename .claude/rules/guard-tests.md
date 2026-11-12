# Guard Tests

Every standard this repo holds itself to, and ships to other repos, has a
check that fails when the standard breaks, and `bin/ci` runs it.

## The Rule

- `starter/tests/guards` is the one guard suite: this repo runs it on itself
  through `starter/tests/run`, and every repo that copies `starter/` runs the
  same file. It checks the 65,536-byte file cap, suppression comments, lint
  configuration, every bash script (shellcheck, shfmt, strict mode), every
  Markdown file (markdownlint), the size and shape of `CLAUDE.md` and every
  rule, and the permissions and hooks in `.claude/settings.json`. This repo's
  `.claude/settings.json` and `.claude/hooks/` are symlinks to the starter's,
  so it runs under exactly what it ships.
- `tests/run` feeds the `require-bin` hook commands it must block and
  commands it must allow.
- `starter/tests/run` pins every cap in the guards; changing a cap edits
  both files in the same change.
- `tests/run` also copies `starter/` and every language's rules into a
  throwaway repo, proves the guards pass there through `bin/ci`, and proves
  each check fails on a planted violation.
- A new standard, script or helper lands with its check, and a new check
  lands with the planted violation that proves it.
- A check never contains a token it bans; it builds the token at run time.

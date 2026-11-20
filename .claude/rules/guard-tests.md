# Guard Tests

Every standard this repo holds itself to, and ships to other repos, has a
check that fails when the standard breaks, and `bin/ci` runs it.

## The Rule

- `starter/tests/guards` is the one guard suite, and
  `starter/.claude/rules/guard-tests.md` states what it checks and how
  its caps are pinned; this repo runs it through `starter/tests/run`.
  This repo's `.claude/settings.json`, `.claude/hooks/` and
  `rule-authoring.md` are symlinks to the starter's, so it runs under
  exactly what it ships.
- `tests/run` feeds the `require-bin` hook commands it must block and
  commands it must allow, and drives `bin/commit` through every refusal
  with a stand-in `claude`.
- `tests/run` also copies `starter/` and every language's rules into a
  throwaway repo, proves the guards pass there through `bin/ci`, and proves
  each check fails on a planted violation.
- A new script or helper lands with its check, and a new check lands with
  the planted violation that proves it. Trigger: any change that adds a
  script, helper or check under `starter/` or `bin/`.
- A check never contains a token it bans; it builds the token at run time.
<!-- audited: 2ac473df79ed -->

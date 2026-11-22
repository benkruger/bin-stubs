# Guard Tests

Every standard this repo holds itself to, and ships to other repos, has a
check that fails when the standard breaks, and `bin/ci` runs it.

## The Rule

- `starter/tests/guards` is the one guard suite, and
  `starter/.claude/rules/guard-tests.md` states that `tests/run` runs it
  and pins its caps; this repo runs it through `starter/tests/run`.
  This repo's `.claude/hooks/` and `rule-authoring.md` are symlinks to
  the starter's. Its `.claude/settings.json` is the starter's less the
  denies on editing the gate that `test_settings` in `tests/core` lists;
  `tests/run` fails a starter settings file missing one of those
  denies, and this repo's settings file when it is not the starter's
  less them. Trigger: any change to either settings file.
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
<!-- audited: 920be4a2513c -->

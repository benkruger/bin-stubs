# Guard Tests

Every standard the repo holds itself to has a check that fails when the
standard breaks: for code, a check `bin/ci` runs; for a rule's text, the
review `bin/commit` runs.

## The Rule

- `tests/run` is the repo-level suite `bin/ci` runs, and it runs
  `tests/guards`; a failing suite fails `bin/ci` as
  `every-test-runs.md` states. Trigger: any change to `tests/run` or
  `tests/guards`.
- `tests/run` fails when a cap in `tests/guards` differs from the value it
  pins. A change to a cap edits both files together. Trigger: any change
  to a cap.
- The review `bin/commit` runs checks a rule's text, as `rule-authoring.md`
  states. Trigger: any change to a file under `.claude/rules/`.
- A rule that states a standard on code names the check `bin/ci` runs
  that fails it, such as a `tests/guards` check, and lands in the same
  change as that check; the review `rule-authoring.md` describes refuses
  a rule that does not describe its check exactly as it works. Trigger: a
  new or edited rule under `.claude/rules/`.
<!-- audited: eedf1fac2dd3 -->

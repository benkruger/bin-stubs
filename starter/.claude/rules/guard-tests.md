# Guard Tests

Every standard the repo holds itself to has a check that fails when the
standard breaks: a `tests/guards` check `bin/ci` runs, or the review.

## The Rule

- `tests/run` is the repo-level suite `bin/ci` runs, and it runs
  `tests/guards`; a failing suite fails `bin/ci` as
  `every-test-runs.md` states. Trigger: any change to `tests/run` or
  `tests/guards`.
- `tests/run` fails when a cap in `tests/guards` differs from the value it
  pins. A change to a cap edits both files together. Trigger: any change
  to a cap.
- A new standard lands in the same change as its `tests/guards` check,
  or names the review as its check; the review refuses a rule that does
  neither. Trigger: a new rule under `.claude/rules/`.
<!-- audited: 50cb6df2e5a9 -->

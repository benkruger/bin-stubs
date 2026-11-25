# CLAUDE.md

`CLAUDE.md` holds how the agent works in this repo, short enough to read
whole in every session.

## The Rule

- `CLAUDE.md` is at most 400 lines and 12,000 characters, leads with one
  H1 and holds only how the agent works; rules load on their own and live
  only in `.claude/rules/`. `tests/guards` fails a `CLAUDE.md` over either
  bound, without that H1, with `BACKWARD_FACING` wording, or that
  references that folder or a rule in it. Trigger: any edit to
  `CLAUDE.md`.
<!-- audited: 85d06309e2f3 -->

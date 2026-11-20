# CLAUDE.md

`CLAUDE.md` holds how the agent works in this repo, short enough to read
whole in every session.

## The Rule

- `CLAUDE.md` is at most 400 lines and 12,000 characters and leads with one
  H1; `tests/guards` fails it otherwise.
- `CLAUDE.md` holds only how the agent works: commands, workflow and
  repo layout. Rules load on their own, so `tests/guards` fails a
  `CLAUDE.md` that names a rule file or the rules folder. Trigger: any
  edit to `CLAUDE.md`.
<!-- audited: e7ccb7f51a2f -->

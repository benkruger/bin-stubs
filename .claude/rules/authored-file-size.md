# Authored File Size

This repo holds itself to the file-size cap it ships, stated in
`starter/.claude/rules/authored-file-size.md`.

## The Rule

- `starter/tests/guards` runs on this repo too, so every authored text file
  here meets that cap and its exemptions; the guard fails the file that
  does not.
- A script that would exceed the cap splits as
  `starter/.claude/rules/authored-file-size.md` states, into a helper it
  sources. Trigger: an edit that takes a script near the cap.
<!-- audited: 24b55607281c -->

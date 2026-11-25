# Deleted Files

`bin/changed` counts a file deleted since the last commit as a change.

## The Rule

- `bin/changed` reads the deletions `deleted_paths` in `bin/lib/deletions.sh`
  lists. A language that tests its whole suite (Rust, iOS, shell) runs it
  when the only change is a deletion; a language that pairs each source with
  a twin test (TypeScript, JavaScript, Python, Rails) fails, as
  `deleted_twin_findings` reports, a source whose twin was deleted and a test
  whose source was deleted. `tests/run` fails a Rust or iOS `bin/changed`
  that skips its suite when only a file was deleted, and a twin language
  whose `bin/changed` passes either deletion. Trigger: any change to a
  `bin/changed` or to `bin/lib/deletions.sh`.
<!-- audited: dd7218b1b552 -->

# Authored File Size

Every authored text file is at most 65,536 bytes.

## The Rule

- `tests/guards` fails any tracked or new text file over 65,536 bytes.
- A file that would exceed the cap is split by responsibility into smaller
  files, each with its own twin test. The cap never rises. Trigger: an edit
  that takes a file past the cap.
- Generated lockfiles are exempt by name in `GENERATED_NAMES`. Any other
  exemption is an exact path in `EXEMPT_PATHS`, never a glob.
- Binary files are not authored text and are not measured.
<!-- audited: b99e8a25a5cc -->

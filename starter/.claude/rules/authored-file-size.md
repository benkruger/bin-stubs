# Authored File Size

Every authored text file is at most 65,536 bytes.

## The Rule

- `tests/guards` fails any tracked or new text file over 65,536 bytes.
- A file that would pass the cap is split by responsibility into smaller
  files, each with its own twin test. The cap never rises.
- Generated lockfiles are exempt by name in `GENERATED_NAMES`. Any other
  exemption is an exact path in `EXEMPT_PATHS`, never a glob.
- Binary files are not authored text and are not measured.

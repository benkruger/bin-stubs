# Script Standards

Every script here meets `starter/.claude/rules/script-standards.md`, because
it runs unattended in other people's repos.

## The Rule

- Every script starts with `#!/usr/bin/env bash`; `tests/run` fails any
  other shebang.
- A script nothing calls is deleted, not shipped. Trigger: a change that
  removes a script's last caller deletes the script in the same change.
<!-- audited: a151f7b5215c -->

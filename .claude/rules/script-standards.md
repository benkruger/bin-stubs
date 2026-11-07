# Script Standards

Every script in the kit is strict, shellcheck-clean bash, because it runs
unattended in other people's repos.

## The Rule

- Every script starts with `#!/usr/bin/env bash`; `tests/run` checks it.
- An entry point is executable and its first command is
  `set -euo pipefail`. A sourced helper (`lib/*.sh`, `_run_quiet`,
  `tests/lib.sh`) is never run directly.
- `shellcheck -x -P SCRIPTDIR` reports nothing for any script. A finding is
  fixed in the code; a `# shellcheck source=` directive is the only
  shellcheck comment allowed.
- A sourced helper uses only what it defines or receives as arguments,
  never a variable its caller happens to set.
- A script nothing calls is deleted, not shipped.
- `starter/tests/guards` enforces the rest.

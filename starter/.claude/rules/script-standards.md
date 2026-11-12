# Script Standards

Every bash script in the repo is strict, formatted and shellcheck-clean,
because the gate runs it unattended.

## The Rule

- An entry point is executable and its first command is
  `set -euo pipefail`. A sourced helper (`lib/*.sh`, `_run_quiet`,
  `tests/lib.sh`) is never run directly.
- `shellcheck -x -P SCRIPTDIR` reports nothing for any bash script. A
  `# shellcheck source=` directive is the only shellcheck comment allowed.
- Every bash script is formatted exactly as `shfmt -i 2 -ci` writes it;
  `bin/format` writes it that way.
- A sourced helper uses only what it defines or receives as arguments.
- `tests/guards` enforces all of the above.

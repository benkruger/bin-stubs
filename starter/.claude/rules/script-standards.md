# Script Standards

Every bash script in the repo is strict, formatted and shellcheck-clean,
because the gate runs it unattended.

## The Rule

- An entry point is executable and its first command is
  `set -euo pipefail`.
- `shellcheck -x -P SCRIPTDIR` reports nothing for any bash script. A
  `# shellcheck source=` directive is the only shellcheck comment allowed.
- Every bash script is formatted exactly as `shfmt -i 2 -ci` writes it;
  `bin/format` writes it that way.
- `tests/guards` fails an entry point that is not executable or does not
  start with `set -euo pipefail`, a shellcheck finding and a shfmt diff.
  Trigger: any new or edited bash script.
- A sourced helper (`lib/*.sh`, `_run_quiet`, `tests/lib.sh`) is never run
  directly and uses only what it defines or receives as arguments; review
  holds it there. Trigger: any new file under `lib/`.
<!-- audited: 2383b4d9fa60 -->

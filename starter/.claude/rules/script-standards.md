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
- A bash script is a file named `*.sh` or `*.bash`, or one whose shebang
  names bash. `tests/guards` fails an entry point that is not executable or
  does not start with `set -euo pipefail`, a shellcheck finding and a
  shfmt diff, and fails when shellcheck or shfmt is not installed. It
  runs shellcheck with `SHELLCHECK_OPTS` unset, and skips it when the same
  scripts, with the same contents, passed it before under the same
  shellcheck version and the same rc files at the same paths: each
  `.shellcheckrc` and `shellcheckrc` in the repo and its parent folders,
  `~/.shellcheckrc` and `shellcheckrc` in `XDG_CONFIG_HOME` or
  `~/.config`. It marks a pass under `flow-guards/shellcheck` in
  `XDG_CACHE_HOME` or `~/.cache`. Trigger: any new or edited bash script.
- A sourced helper (`lib/*.sh`, `_run_quiet`, `tests/lib.sh`) is not an
  entry point, so `tests/guards` skips its executable and
  `set -euo pipefail` checks. Trigger: any new or edited sourced helper.
<!-- audited: b37393f28b42 -->

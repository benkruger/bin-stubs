#!/usr/bin/env bash
# Sourced by bin/ci. toolchain_check <root> passes when the active bun is the
# version pinned in <root>/.bun-version, and explains the fix otherwise.

toolchain_check() {
  local root="$1" pinned active
  if [ ! -f "$root/.bun-version" ]; then
    echo "toolchain: .bun-version is missing; pin bun with: bun --version > .bun-version" >&2
    return 1
  fi
  pinned="$(tr -d '[:space:]' <"$root/.bun-version")"
  if ! active="$(bun --version 2>/dev/null)"; then
    echo "toolchain: bun is not installed; .bun-version pins $pinned" >&2
    return 1
  fi
  if [ "$active" != "$pinned" ]; then
    echo "toolchain: bun $active is active but .bun-version pins $pinned; install it with: curl -fsSL https://bun.sh/install | bash -s bun-v$pinned" >&2
    return 1
  fi
}

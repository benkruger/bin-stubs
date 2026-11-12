#!/usr/bin/env bash
# Sourced by bin/ci. toolchain_check <root> activates the Node pinned in
# <root>/.nvmrc through nvm when nvm is installed, then passes when the active
# Node is that version, and explains the fix otherwise. It never installs a
# Node itself.

toolchain_check() {
  local root="$1" pinned active nvm_script options
  if [ ! -f "$root/.nvmrc" ]; then
    echo "toolchain: .nvmrc is missing; pin Node with: node --version | sed 's/^v//' > .nvmrc" >&2
    return 1
  fi
  pinned="$(tr -d '[:space:]' <"$root/.nvmrc")"
  pinned="${pinned#v}"

  nvm_script="${NVM_DIR:-$HOME/.nvm}/nvm.sh"
  if [ -s "$nvm_script" ]; then
    options="$-"
    set +eu
    # shellcheck source=/dev/null
    . "$nvm_script"
    nvm use "$pinned" >/dev/null 2>&1
    case "$options" in *e*) set -e ;; esac
    case "$options" in *u*) set -u ;; esac
  fi

  if ! active="$(node --version 2>/dev/null)"; then
    echo "toolchain: node is not installed; .nvmrc pins $pinned (nvm install $pinned)" >&2
    return 1
  fi
  active="${active#v}"
  if [ "$active" != "$pinned" ]; then
    echo "toolchain: node $active is active but .nvmrc pins $pinned; install it with: nvm install $pinned" >&2
    return 1
  fi
}

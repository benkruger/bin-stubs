#!/usr/bin/env bash
# Sourced by every bin/ script. toolchain_check <root> activates the Node
# pinned in <root>/.nvmrc through nvm when it is not already active and nvm
# is installed, then passes when the active
# Node is that version and the active package manager is the one
# <root>/package.json pins in packageManager, and explains the fix
# otherwise. It never installs a Node or a package manager itself.

toolchain_check() {
  local root="$1" pinned active nvm_script options manager name version current
  if [ ! -f "$root/.nvmrc" ]; then
    echo "toolchain: .nvmrc is missing; pin Node with: node --version | sed 's/^v//' > .nvmrc" >&2
    return 1
  fi
  pinned="$(tr -d '[:space:]' <"$root/.nvmrc")"
  pinned="${pinned#v}"

  active="$(node --version 2>/dev/null || true)"
  nvm_script="${NVM_DIR:-$HOME/.nvm}/nvm.sh"
  if [ "${active#v}" != "$pinned" ] && [ -s "$nvm_script" ]; then
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

  manager="$(node -p 'require(process.argv[1]).packageManager || ""' "$root/package.json")"
  if [ -z "$manager" ]; then
    echo "toolchain: package.json pins no packageManager; pin npm with: npm pkg set packageManager=npm@\$(npm --version)" >&2
    return 1
  fi
  name="${manager%%@*}"
  version="${manager#*@}"
  version="${version%%+*}"
  case "$name" in
    npm | pnpm | yarn | bun) ;;
    *)
      echo "toolchain: package.json pins an unknown packageManager: $manager" >&2
      return 1
      ;;
  esac
  if [ "$name" = bun ]; then
    PATH="${HOME}/.bun/bin:${PATH}"
  fi
  if ! current="$("$name" --version 2>/dev/null)"; then
    echo "toolchain: $name is not installed; package.json pins $name@$version" >&2
    return 1
  fi
  if [ "$current" != "$version" ]; then
    echo "toolchain: $name $current is active but package.json pins $version; install it with: npm install -g $name@$version" >&2
    return 1
  fi
}

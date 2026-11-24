#!/usr/bin/env bash

pm_version() {
  local name="$1" path link pkg found hops=0
  path="$(command -v "$name")" || return 1
  while [ -L "$path" ] && [ "$hops" -lt 40 ]; do
    link="$(readlink "$path")"
    case "$link" in
      /*) path="$link" ;;
      *) path="${path%/*}/$link" ;;
    esac
    hops=$((hops + 1))
  done
  pkg="${path%/bin/*}/package.json"
  if [ "$pkg" != "$path/package.json" ] && [ -f "$pkg" ] &&
    found="$(jq -r --arg name "$name" 'select(.name == $name) | .version // empty' "$pkg" 2>/dev/null)" &&
    [ -n "$found" ]; then
    printf '%s\n' "$found"
    return 0
  fi
  "$name" --version 2>/dev/null
}

toolchain_check() {
  local root="$1" pinned active nvm_script options manager name version current
  [ "${FLOW_CHECKED_APP:-}" != "$root" ] || return 0
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
    active="$(node --version 2>/dev/null || true)"
  fi

  if [ -z "$active" ]; then
    echo "toolchain: node is not installed; .nvmrc pins $pinned (nvm install $pinned)" >&2
    return 1
  fi
  active="${active#v}"
  if [ "$active" != "$pinned" ]; then
    echo "toolchain: node $active is active but .nvmrc pins $pinned; install it with: nvm install $pinned" >&2
    return 1
  fi

  manager="$(jq -r '.packageManager // ""' "$root/package.json" 2>/dev/null || true)"
  name="${manager%%@*}"
  version="${manager#*@}"
  version="${version%%+*}"
  if [ "$name" != npm ] || [ "$version" = "$manager" ]; then
    echo "toolchain: package.json pins ${manager:-no packageManager}; pin npm with: npm pkg set packageManager=npm@\$(npm --version)" >&2
    return 1
  fi
  if ! current="$(pm_version npm)"; then
    echo "toolchain: npm is not installed; package.json pins npm@$version" >&2
    return 1
  fi
  if [ "$current" != "$version" ]; then
    echo "toolchain: npm $current is active but package.json pins $version; install it with: npm install -g npm@$version" >&2
    return 1
  fi
}

packages_check() {
  local root="$1"
  [ "${FLOW_CHECKED_APP:-}" != "$root" ] || return 0
  if [ ! -d "$root/node_modules" ]; then
    echo "packages: node_modules is missing; run bin/dependencies" >&2
    return 1
  fi
  if ! (cd "$root" && npm ls --depth=0 >/dev/null 2>&1); then
    echo "packages: node_modules does not match package.json; run bin/dependencies" >&2
    return 1
  fi
}

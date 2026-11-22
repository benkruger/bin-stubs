#!/usr/bin/env bash

# shellcheck source=apps.sh
. "$(dirname "${BASH_SOURCE[0]}")/apps.sh"

run_app_script() {
  local script="$1" root app dir lang
  shift
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  app="."
  if [ "$#" -gt 0 ] && [ -d "$root/$1" ] && is_app_dir "$root/$1"; then
    app="$1"
    shift
  fi
  dir="$(cd "$root/$app" && pwd)"
  if ! lang="$(app_language "$dir")"; then
    echo "usage: bin/$script [app] [args...]; $app is not an app" >&2
    exit 2
  fi
  if [ ! -x "$root/bin/_$lang/$script" ]; then
    echo "bin/$script: a $lang app has no bin/$script" >&2
    exit 2
  fi
  cd "$dir" || exit 1
  APP_DIR="$dir" exec "$root/bin/_$lang/$script" "$@"
}

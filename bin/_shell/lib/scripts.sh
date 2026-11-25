#!/usr/bin/env bash

# shellcheck source=../../lib/apps.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/apps.sh"

SHELL_ROOT_APP=0
if [ "$(pwd -P)" = "$(git rev-parse --show-toplevel 2>/dev/null)" ]; then
  SHELL_ROOT_APP=1
fi

in_nested_app() {
  local top="${1%%/*}"
  [ "$SHELL_ROOT_APP" -eq 1 ] && [ "$top" != "$1" ] && is_app_dir "$PWD/$top"
}

shell_listing() {
  local all=0 arg
  local paths=()
  for arg in "$@"; do
    case "$arg" in
      --all) all=1 ;;
      --check) ;;
      *) paths+=("$arg") ;;
    esac
  done
  if [ "$all" -eq 1 ]; then
    git ls-files --cached --others --exclude-standard -- .
  elif [ "${#paths[@]}" -gt 0 ]; then
    printf '%s\n' "${paths[@]}"
  else
    "$(dirname "${BASH_SOURCE[0]}")/../changed" --files
  fi
}

shell_scripts() {
  local path first shebang='^#!.*[/[:space:]](ba)?sh([[:space:]]|$)'
  while IFS= read -r path; do
    [ -n "$path" ] && [ -f "$path" ] && [ ! -L "$path" ] || continue
    ! in_nested_app "$path" || continue
    case "$path" in
      .flow-states/* | */.flow-states/* | node_modules/* | */node_modules/*) continue ;;
      *.sh | *.bash)
        printf '%s\n' "$path"
        continue
        ;;
    esac
    first=""
    IFS= read -r first <"$path" || true
    if [[ "$first" =~ $shebang ]]; then
      printf '%s\n' "$path"
    fi
  done
}

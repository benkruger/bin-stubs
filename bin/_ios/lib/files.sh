#!/usr/bin/env bash

app_files() {
  local path top root_app=0
  APP_FILES=()
  if [ "$(pwd -P)" = "$(git rev-parse --show-toplevel)" ]; then
    root_app=1
  fi
  while IFS= read -r -d '' path; do
    [ -f "$path" ] && [ ! -L "$path" ] || continue
    case "$path" in
      .build/* | */.build/* | .flow-states/* | */.flow-states/*) continue ;;
    esac
    top="${path%%/*}"
    if [ "$root_app" -eq 1 ] && [ "$top" != "$path" ] && is_app_dir "$PWD/$top"; then
      continue
    fi
    APP_FILES+=("$path")
  done < <(git ls-files -z --cached --others --exclude-standard -- "$@")
}

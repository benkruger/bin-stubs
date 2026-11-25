#!/usr/bin/env bash

# shellcheck source=apps.sh
. "$(dirname "${BASH_SOURCE[0]}")/apps.sh"

change_base() {
  if git rev-parse --verify -q HEAD >/dev/null; then
    echo HEAD
  else
    git hash-object -t tree /dev/null
  fi
}

deleted_paths() {
  local root_app=0 path top
  [ "$(pwd -P)" != "$(git rev-parse --show-toplevel 2>/dev/null)" ] || root_app=1
  while IFS= read -r path; do
    [ -n "$path" ] && [ ! -e "$path" ] && [ ! -L "$path" ] || continue
    case "$path" in
      .flow-states/* | */.flow-states/*) continue ;;
    esac
    top="${path%%/*}"
    if [ "$root_app" -eq 1 ] && [ "$top" != "$path" ] && is_app_dir "$PWD/$top"; then
      continue
    fi
    printf '%s\n' "$path"
  done < <(git diff --name-only --no-renames --relative HEAD -- . 2>/dev/null)
}

deleted_twin_findings() {
  local path src twin mirror
  while IFS= read -r path; do
    if is_test "$path"; then
      src="$(source_for_test "$path")"
      [ -n "$src" ] && [ -f "$src" ] || continue
      twin="$(test_for_source "$src")"
      [ -f "$twin" ] || printf 'bin/changed: no mirrored test for %s → %s\n' "$src" "$twin"
    elif is_source "$path"; then
      mirror="$(test_for_source "$path")"
      [ ! -f "$mirror" ] || printf 'bin/changed: no source for test %s\n' "$mirror"
    fi
  done < <(deleted_paths)
}

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

diff_listing() {
  [ -z "${DIFF_LISTED:-}" ] || return 0
  DIFF_LISTING="$(git diff -z --name-only --no-renames --relative "$(change_base)" -- . | tr '\0' '\n')" || return 1
  DIFF_LISTED=1
}

changed_listing() {
  local others
  diff_listing || return 1
  others="$(git ls-files -z --others --exclude-standard -- . | tr '\0' '\n')" || return 1
  printf '%s\n%s\n' "$DIFF_LISTING" "$others" | sort -u | awk '$0 != ".ci-timeout" && $0 !~ /\/\.ci-timeout$/'
}

deleted_paths() {
  local root_app=0 path top
  [ "$(pwd -P)" != "$(git rev-parse --show-toplevel 2>/dev/null)" ] || root_app=1
  diff_listing || return 1
  while IFS= read -r path; do
    [ -n "$path" ] && [ ! -e "$path" ] && [ ! -L "$path" ] || continue
    case "$path" in
      .flow-states/* | */.flow-states/* | .ci-timeout | */.ci-timeout) continue ;;
    esac
    top="${path%%/*}"
    if [ "$root_app" -eq 1 ] && [ "$top" != "$path" ] && is_app_dir "$PWD/$top"; then
      continue
    fi
    printf '%s\n' "$path"
  done <<<"$DIFF_LISTING"
}

deleted_twin_findings() {
  local path src twin mirror deleted
  deleted="$(deleted_paths)" || return 1
  while IFS= read -r path; do
    if is_test "$path"; then
      src="$(source_for_test "$path")"
      [ -n "$src" ] && [ -f "$src" ] || continue
      ! declare -F needs_twin >/dev/null || needs_twin "$src" || continue
      twin="$(test_for_source "$src")"
      [ -f "$twin" ] || printf 'bin/changed: no mirrored test for %s → %s\n' "$src" "$twin"
    elif is_source "$path"; then
      mirror="$(test_for_source "$path")"
      [ ! -f "$mirror" ] || printf 'bin/changed: no source for test %s\n' "$mirror"
    fi
  done <<<"$deleted"
}

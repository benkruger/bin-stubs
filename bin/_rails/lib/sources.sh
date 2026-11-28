#!/usr/bin/env bash

# shellcheck source=../../lib/apps.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/apps.sh"

NESTED_APPS=()
if [ "$(pwd -P)" = "$(git rev-parse --show-toplevel 2>/dev/null)" ]; then
  for nested_dir in */; do
    nested_dir="${nested_dir%/}"
    if [ -d "$nested_dir" ] && is_app_dir "$PWD/$nested_dir"; then
      NESTED_APPS+=("$nested_dir")
    fi
  done
fi

in_nested_app() {
  local dir
  for dir in ${NESTED_APPS[@]+"${NESTED_APPS[@]}"}; do
    case "$1" in
      "$dir"/*) return 0 ;;
    esac
  done
  return 1
}

rubocop_targets() {
  local path listing
  RUBOCOP_TARGETS=()
  listing="$(bundle exec rubocop --list-target-files)" || return 1
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    in_nested_app "$path" || RUBOCOP_TARGETS+=("$path")
  done <<<"$listing"
}

is_source() {
  case "$1" in
    app/*.rb | lib/*.rb) return 0 ;;
    *) return 1 ;;
  esac
}

is_test() {
  case "$1" in
    test/system/*) return 1 ;;
    test/*_test.rb) return 0 ;;
    *) return 1 ;;
  esac
}

test_for_source() {
  case "$1" in
    app/*)
      local rel="${1#app/}"
      echo "test/${rel%.rb}_test.rb"
      ;;
    lib/*)
      echo "test/${1%.rb}_test.rb"
      ;;
  esac
}

source_for_test() {
  local rel="${1#test/}"
  rel="${rel%_test.rb}.rb"
  case "$rel" in
    lib/*)
      if [ ! -f "$rel" ] && [ -f "app/$rel" ]; then
        rel="app/$rel"
      fi
      printf '%s\n' "$rel"
      ;;
    *) printf 'app/%s\n' "$rel" ;;
  esac
}

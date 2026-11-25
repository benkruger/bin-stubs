#!/usr/bin/env bash

at_repo_root() {
  if [ "$(pwd -P)" = "$(git rev-parse --show-toplevel)" ]; then
    echo 1
  else
    echo 0
  fi
}

app_file() {
  local path="$1" root_app="$2" links="${3:-}" top
  [ -f "$path" ] || return 1
  [ -n "$links" ] || [ ! -L "$path" ] || return 1
  case "$path" in
    .build/* | */.build/* | .flow-states/* | */.flow-states/*) return 1 ;;
  esac
  top="${path%%/*}"
  ! { [ "$root_app" -eq 1 ] && [ "$top" != "$path" ] && is_app_dir "$PWD/$top"; }
}

app_files() {
  local path root_app links="" listed
  if [ "${1:-}" = --links ]; then
    links=1
    shift
  fi
  APP_FILES=()
  root_app="$(at_repo_root)"
  listed="$(mktemp "${TMPDIR:-/tmp}/bin-ios-files.XXXXXX")"
  if ! git ls-files -z --cached --others --exclude-standard -- "$@" >"$listed"; then
    rm -f "$listed"
    return 1
  fi
  while IFS= read -r -d '' path; do
    app_file "$path" "$root_app" "$links" || continue
    APP_FILES+=("$path")
  done <"$listed"
  rm -f "$listed"
}

swift_files() {
  local all="$1" here="$2" path root_app listing
  shift 2
  SWIFT_FILES=()
  if [ "$all" -eq 1 ]; then
    app_files '*.swift'
    SWIFT_FILES=(${APP_FILES[@]+"${APP_FILES[@]}"})
    return 0
  fi
  if [ "$#" -eq 0 ]; then
    listing="$("$here/changed" --files)" || return 1
    while IFS= read -r path; do
      [ -z "$path" ] || set -- "$@" "$path"
    done <<<"$listing"
  fi
  root_app="$(at_repo_root)"
  for path in "$@"; do
    path="${path#./}"
    case "$path" in
      *.swift) app_file "$path" "$root_app" && SWIFT_FILES+=("$path") ;;
    esac
  done
}

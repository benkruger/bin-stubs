#!/usr/bin/env bash

GATE_LIB="${BASH_SOURCE[0]%/*}"
[ "$GATE_LIB" != "${BASH_SOURCE[0]}" ] || GATE_LIB=.
GATE_DRIVER="${BASH_SOURCE[1]%/*}"
[ "$GATE_DRIVER" != "${BASH_SOURCE[1]}" ] || GATE_DRIVER=.
# shellcheck source=apps.sh
. "${GATE_LIB:-/}/apps.sh"
GATE_LIB="$(cd "${GATE_LIB:-/}" && pwd)"
GATE_DRIVER="$(cd "${GATE_DRIVER:-/}" && pwd)"

gate_fingerprint() {
  local f base="${GATE_LIB%/*}" files=()
  while IFS= read -r f; do
    files+=("$f")
  done < <(find "$GATE_LIB" "$GATE_DRIVER" -type f | LC_ALL=C sort -u)
  [ "${#files[@]}" -gt 0 ] || return 0
  paste -d ' ' <(printf '%s\n' "${files[@]#"$base"/}") <(git hash-object -- "${files[@]}")
}

GATE_PRINT=""
[ "${ROOT_APP:-0}" = 1 ] || GATE_PRINT="$(gate_fingerprint)"

untracked_kept() {
  local path name skip
  while IFS= read -r -d '' path; do
    [ -f "$path" ] || [ -L "$path" ] || continue
    case "$path" in
      .flow-states/* | .venv/* | node_modules/* | vendor/* | target/* | .build/*) continue ;;
    esac
    skip=0
    for name in "$@"; do
      case "$path" in
        "$name" | "$name"/*)
          skip=1
          break
          ;;
      esac
    done
    [ "$skip" -eq 1 ] || printf '%s\0' "$path"
  done
}

content_tree() {
  local dir real prefix tree rc=0
  dir="$(mktemp -d "${TMPDIR:-/tmp}/bin-lib-tree-sentinel.XXXXXX")"
  real="$(git rev-parse --path-format=absolute --git-path index)" || rc=$?
  [ "$rc" -ne 0 ] || [ ! -f "$real" ] || cp "$real" "$dir/index" || rc=$?
  prefix="$(git rev-parse --show-prefix)" || rc=$?
  if [ "$rc" -eq 0 ]; then
    GIT_INDEX_FILE="$dir/index" git add -u &&
      git ls-files -z --others --exclude-standard -- . | untracked_kept "$@" |
      GIT_INDEX_FILE="$dir/index" git update-index --add -z --stdin &&
      GIT_INDEX_FILE="$dir/index" git rm -r -q --cached --ignore-unmatch -- ':(glob)**/.ci-timeout' "$@" &&
      tree="$(GIT_INDEX_FILE="$dir/index" git write-tree ${prefix:+"--prefix=$prefix"})" || rc=$?
  fi
  rm -rf "$dir"
  [ "$rc" -eq 0 ] || return "$rc"
  printf '%s\n' "$tree"
}

root_app_fingerprint() {
  local d excludes=()
  for d in ./*/; do
    [ -d "$d" ] || continue
    if is_app_dir "$d"; then
      d="${d%/}"
      excludes+=("${d#./}")
    fi
  done
  content_tree "${excludes[@]+"${excludes[@]}"}" CLAUDE.md README.md .claude checks
}

tree_fingerprint() {
  if [ "${ROOT_APP:-0}" = 1 ]; then
    root_app_fingerprint
    return
  fi
  content_tree || return
  [ -z "$GATE_PRINT" ] || printf '%s\n' "$GATE_PRINT"
}

tree_hash() {
  local sum
  if command -v sha256sum >/dev/null 2>&1; then
    sum="$(tree_fingerprint | sha256sum)" || return
  else
    sum="$(tree_fingerprint | shasum -a 256)" || return
  fi
  printf '%s\n' "${sum%% *}"
}
